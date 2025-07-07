# frozen_string_literal: true

# Handles single page HTML generation
class PageGenerator
  def initialize(target_dir)
    @target_dir = target_dir
  end

  def generate(path)
    env = Rack::MockRequest.env_for(path, 'HTTP_HOST' => 'www.aozora.gr.jp')
    _status, _headers, response_body = Rails.application.call(env)
    html = +''
    response_body.each { |chunk| html << chunk }
    response_body.close if response_body.respond_to?(:close)

    rel_path = path.sub(%r{^/}, '')
    full_path = @target_dir.join(rel_path)
    write_file(full_path, html)
    full_path
  end

  private

  def write_file(full_path, content)
    dir = File.dirname(full_path)
    FileUtils.mkdir_p(dir)
    File.write(full_path, content)
  end
end
