# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe StaticPageBuilder do
  let(:target_dir) { Rails.root.join('tmp/test_build') }
  let(:builder) { StaticPageBuilder.new(target_dir: target_dir) }

  before do
    FileUtils.rm_rf(target_dir)
    FileUtils.mkdir_p(Rails.public_path.join('assets'))
    # Create test asset files
    FileUtils.touch(Rails.public_path.join('assets', 'application-dummy.css'))
    FileUtils.touch(Rails.public_path.join('assets', 'application-dummy.js'))
  end

  after do
    FileUtils.rm_rf(target_dir)
  end

  describe '#initialize' do
    it 'sets target_dir' do
      expect(builder.target_dir).to eq(target_dir)
    end

    it 'uses default target_dir when not specified' do
      default_builder = StaticPageBuilder.new
      expect(default_builder.target_dir).to eq(Rails.root.join('tmp/build'))
    end

    it 'yields self to block if given' do
      yielded_builder = nil
      StaticPageBuilder.new(target_dir: target_dir) do |b|
        yielded_builder = b
      end
      expect(yielded_builder).to be_a(StaticPageBuilder)
    end
  end

  describe '#copy_precompiled_assets' do
    let(:rake_task) { instance_spy(Rake::Task) }

    before do
      allow(Rake::Task).to receive(:[]).with('assets:precompile').and_return(rake_task)
    end

    it 'invokes assets:precompile task' do
      builder.copy_precompiled_assets
      expect(rake_task).to have_received(:invoke)
    end

    it 'creates assets directory in target_dir' do
      builder.copy_precompiled_assets
      expect(Dir.exist?(target_dir.join('assets'))).to be true
    end

    it 'copies asset files to target directory' do
      builder.copy_precompiled_assets
      expect(File.exist?(target_dir.join('assets', 'application-dummy.css'))).to be true
      expect(File.exist?(target_dir.join('assets', 'application-dummy.js'))).to be true
    end
  end

  describe '#copy_public_images' do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp_r)
    end

    it 'creates images directory and copies images' do
      builder.copy_public_images
      expect(FileUtils).to have_received(:mkdir_p).with(target_dir.join('images'))
      expect(FileUtils).to have_received(:cp_r).with(
        Rails.public_path.join('images'),
        target_dir
      )
    end

    it 'creates cards/images directory and copies card images' do
      builder.copy_public_images
      expect(FileUtils).to have_received(:mkdir_p).with(target_dir.join('cards/images'))
      expect(FileUtils).to have_received(:cp_r).with(
        Rails.public_path.join('cards/images'),
        target_dir.join('cards')
      )
    end
  end

  describe '#copy_zip_files' do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp)
    end

    it 'creates index_pages directory' do
      allow(Rails.root).to receive(:glob).with('data/csv_zip/*.zip')
      builder.copy_zip_files
      expect(FileUtils).to have_received(:mkdir_p).with(target_dir.join('index_pages'))
    end

    it 'copies zip files to index_pages directory' do
      zip_file = Pathname.new(Rails.root.join('data/csv_zip/sample.zip'))
      allow(Rails.root).to receive(:glob).with('data/csv_zip/*.zip') do |&block|
        block&.call(zip_file)
      end

      builder.copy_zip_files
      expect(FileUtils).to have_received(:cp).with(
        zip_file,
        target_dir.join('index_pages')
      )
    end
  end

  describe '#force_clean' do
    before do
      allow(FileUtils).to receive(:remove_entry_secure)
    end

    it 'removes target directory' do
      builder.force_clean
      expect(FileUtils).to have_received(:remove_entry_secure).with(target_dir, :force)
    end
  end

  describe '#build_html' do
    let(:mock_response) { ['<html><body>Test Page</body></html>'] }
    let(:rack_app) { ->(_env) { [200, {}, mock_response] } }

    before do
      allow(Rails).to receive(:application).and_return(rack_app)
      allow(rack_app).to receive(:call).and_return([200, {}, mock_response])
    end

    context 'with single path' do
      it 'generates HTML file for given path' do
        result_path = builder.build_html(path: '/test/path')

        expect(result_path).to eq(target_dir.join('test/path'))
        expect(File.exist?(result_path)).to be true
        expect(File.read(result_path)).to eq('<html><body>Test Page</body></html>')
      end

      it 'creates necessary directories' do
        builder.build_html(path: '/deeply/nested/page')

        expect(Dir.exist?(target_dir.join('deeply/nested'))).to be true
      end

      it 'handles root path correctly' do
        result_path = builder.build_html(path: '/index.html')

        expect(result_path).to eq(target_dir.join('index.html'))
        expect(File.exist?(result_path)).to be true
      end
    end

    context 'with multiple paths' do
      let(:paths) { ['/page1', '/page2', '/page3'] }

      it 'generates all pages sequentially with progress reporting' do
        stats = builder.build_html(paths: paths, verbose: false)

        expect(stats[:success]).to eq(3)
        expect(stats[:failed]).to eq(0)
        expect(stats[:errors]).to be_empty

        paths.each do |path|
          file_path = target_dir.join(path.sub(%r{^/}, ''))
          expect(File.exist?(file_path)).to be true
          expect(File.read(file_path)).to eq('<html><body>Test Page</body></html>')
        end
      end

      it 'handles errors gracefully and continues processing' do
        call_count = 0
        allow(Rails.application).to receive(:call) do
          call_count += 1
          raise StandardError, 'Mock error' if call_count == 1

          [200, {}, mock_response]
        end

        stats = builder.build_html(paths: paths, verbose: false)

        expect(stats[:success]).to eq(2)
        expect(stats[:failed]).to eq(1)
        expect(stats[:errors]).to include('/page1: Mock error')
      end

      it 'returns statistics for the batch operation' do
        stats = builder.build_html(paths: [], verbose: false)

        expect(stats).to have_key(:success)
        expect(stats).to have_key(:failed)
        expect(stats).to have_key(:errors)
      end

      it 'handles empty paths array' do
        stats = builder.build_html(paths: [], verbose: false)

        expect(stats[:success]).to eq(0)
        expect(stats[:failed]).to eq(0)
        expect(stats[:errors]).to be_empty
      end

      it 'handles nil paths' do
        stats = builder.build_html(paths: nil, verbose: false)

        expect(stats[:success]).to eq(0)
        expect(stats[:failed]).to eq(0)
        expect(stats[:errors]).to be_empty
      end
    end

    context 'without path or paths' do
      it 'returns empty stats when neither path nor paths provided' do
        stats = builder.build_html(verbose: false)

        expect(stats[:success]).to eq(0)
        expect(stats[:failed]).to eq(0)
        expect(stats[:errors]).to be_empty
      end
    end
  end

  describe '#create_rsync_keyfile' do
    let(:keyfile_path) { '/tmp/rsync.key' }
    let(:key_data) do
      '-----BEGIN OPENSSH PRIVATE KEY-----@NL@b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcn@NL@B4FbIgEwUY6VQhG0nkaRmjPXTH1R8y/XJnpA5jO3GuPnnlACx8K8Yj5W8X4kQAAAAt0ZXN@NL@QGV4YW1wbGU=@NL@-----END OPENSSH PRIVATE KEY-----@NL@'
    end

    before do
      allow(File).to receive(:write)
      allow(FileUtils).to receive(:chmod)
    end

    it 'writes key data to the keyfile' do
      expected_data = <<~KEY
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcn
        B4FbIgEwUY6VQhG0nkaRmjPXTH1R8y/XJnpA5jO3GuPnnlACx8K8Yj5W8X4kQAAAAt0ZXN
        QGV4YW1wbGU=
        -----END OPENSSH PRIVATE KEY-----
      KEY
      builder.create_rsync_keyfile(key_data)
      expect(File).to have_received(:write).with(keyfile_path, expected_data)
    end

    it 'sets proper permissions on the keyfile' do
      builder.create_rsync_keyfile(key_data)
      expect(FileUtils).to have_received(:chmod).with(0o600, keyfile_path)
    end

    it 'converts @NL@ to actual newlines' do
      escaped_data = 'line1@NL@line2@NL@line3'
      expected_data = "line1\nline2\nline3"
      builder.create_rsync_keyfile(escaped_data)
      expect(File).to have_received(:write).with(keyfile_path, expected_data)
    end
  end
end
