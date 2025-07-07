# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe StaticPageBuilder do
  let(:target_dir) { Rails.root.join('tmp/test_build') }
  let(:builder) { StaticPageBuilder.new(target_dir: target_dir) }

  before do
    FileUtils.rm_rf(target_dir)
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
    let(:assets_path) { instance_spy(Pathname) }

    before do
      allow(Rake::Task).to receive(:[]).with('assets:precompile').and_return(rake_task)
      allow(Rails.public_path).to receive(:join).with('assets').and_return(assets_path)
      allow(assets_path).to receive(:children).and_return([
                                                            Pathname.new('application.css'),
                                                            Pathname.new('application.js')
                                                          ])
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp_r)
    end

    it 'invokes assets:precompile task' do
      builder.copy_precompiled_assets
      expect(rake_task).to have_received(:invoke)
    end

    it 'creates assets directory in target_dir' do
      builder.copy_precompiled_assets
      expect(FileUtils).to have_received(:mkdir_p).with(target_dir.join('assets'))
    end

    it 'copies asset files to target directory' do
      builder.copy_precompiled_assets
      expect(FileUtils).to have_received(:cp_r).at_least(:once)
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
    let(:rack_mock_request) { class_spy(Rack::MockRequest) }

    before do
      stub_const('Rack::MockRequest', rack_mock_request)
      allow(Rails).to receive(:application).and_return(rack_app)
      allow(rack_app).to receive(:call).and_return([200, {}, mock_response])
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
    end

    it 'creates a mock request for the given path' do
      allow(rack_mock_request).to receive(:env_for).and_return({})
      builder.build_html(path: '/test/path')
      expect(rack_mock_request).to have_received(:env_for).with(
        '/test/path',
        'HTTP_HOST' => 'www.aozora.gr.jp'
      )
    end

    it 'calls Rails application with the mock request' do
      builder.build_html(path: '/test/path')
      expect(rack_app).to have_received(:call)
    end

    it 'writes HTML to the correct file path' do
      builder.build_html(path: '/test/path')
      expect(File).to have_received(:write).with(
        target_dir.join('test/path'),
        '<html><body>Test Page</body></html>'
      )
    end

    it 'creates necessary directories before writing' do
      builder.build_html(path: '/test/path')
      expect(FileUtils).to have_received(:mkdir_p).with(target_dir.join('test').to_s)
    end

    it 'handles root path correctly' do
      builder.build_html(path: '/index.html')
      expect(File).to have_received(:write).with(
        target_dir.join('index.html'),
        '<html><body>Test Page</body></html>'
      )
    end
  end

  describe '#create_rsync_keyfile' do
    let(:keyfile_path) { '/tmp/rsync.key' }
    let(:key_data) do
      '-----BEGIN OPENSSH PRIVATE KEY-----\\nb3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcn\\nB4FbIgEwUY6VQhG0nkaRmjPXTH1R8y/XJnpA5jO3GuPnnlACx8K8Yj5W8X4kQAAAAt0ZXN\\nQGV4YW1wbGU=\\n-----END OPENSSH PRIVATE KEY-----\\n'
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

    it 'converts escaped newlines to actual newlines' do
      escaped_data = 'line1\\nline2\\nline3'
      expected_data = "line1\nline2\nline3"
      builder.create_rsync_keyfile(escaped_data)
      expect(File).to have_received(:write).with(keyfile_path, expected_data)
    end
  end
end
