# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PageGenerator do
  let(:target_dir) { Rails.root.join('tmp/test_build') }
  let(:generator) { PageGenerator.new(target_dir) }

  before do
    FileUtils.rm_rf(target_dir)
  end

  after do
    FileUtils.rm_rf(target_dir)
  end

  describe '#generate' do
    let(:mock_response) { ['<html><body>Test Page</body></html>'] }
    let(:rack_app) { ->(_env) { [200, {}, mock_response] } }

    before do
      allow(Rails).to receive(:application).and_return(rack_app)
      allow(rack_app).to receive(:call).and_return([200, {}, mock_response])
    end

    it 'generates HTML file for given path' do
      result_path = generator.generate('/test/path')

      expect(result_path).to eq(target_dir.join('test/path'))
      expect(File.exist?(result_path)).to be true
      expect(File.read(result_path)).to eq('<html><body>Test Page</body></html>')
    end

    it 'creates necessary directories' do
      generator.generate('/deeply/nested/page')

      expect(Dir.exist?(target_dir.join('deeply/nested'))).to be true
    end

    it 'handles root path correctly' do
      result_path = generator.generate('/index.html')

      expect(result_path).to eq(target_dir.join('index.html'))
      expect(File.exist?(result_path)).to be true
    end

    context 'when response body is closeable' do
      let(:closeable_response) do
        instance_spy(File, each: proc { |&block| block.call('<html>Test</html>') }, close: nil)
      end

      before do
        allow(closeable_response).to receive(:respond_to?).with(:close).and_return(true)
        allow(rack_app).to receive(:call).and_return([200, {}, closeable_response])
      end

      it 'closes the response body' do
        allow(closeable_response).to receive(:close)
        generator.generate('/test')
        expect(closeable_response).to have_received(:close)
      end
    end
  end
end
