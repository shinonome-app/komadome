# Static page builder
class StaticPageBuilder
  attr_reader :target_dir, :rsync_keyfile

  def initialize(target_dir: nil)
    @target_dir = target_dir || Rails.root.join('tmp/build')
    @rsync_keyfile = '/tmp/rsync.key'
  end

  def copy_precompiled_assets
    Rake::Task['assets:precompile'].invoke
    FileUtils.mkdir_p(@target_dir.join('assets'))
    Rails.public_path.join('assets').children.each do |file|
      FileUtils.mv(Rails.public_path.join('assets', file), @target_dir.join('assets'))
    end
  end

  def copy_public_images
    FileUtils.mkdir_p(@target_dir.join('images'))
    FileUtils.cp_r(Rails.public_path.join('images'), @target_dir)
  end

  def copy_zip_files
    FileUtils.mkdir_p(@target_dir.join('index_pages'))
    Rails.root.glob('data/csv_zip/*.zip') do |file|
      FileUtils.cp(file, @target_dir.join('index_pages'))
    end
  end

  def force_clean
    FileUtils.remove_entry_secure(@target_dir, :force)
  end

  def build_html(component, path:)
    html = ApplicationController.renderer.render(component, layout: nil)
    rel_path = path.sub(%r{^/}, '')
    full_path = @target_dir.join(rel_path)
    puts "Generate #{full_path}"
    write_with_mkdir(full_path, html)
  end

  def create_rsync_keyfile(data)
    File.write(@rsync_keyfile, data)
    FileUtils.chmod(0o600, @rsync_keyfile)
  end

  private

  def write_with_mkdir(full_path, html)
    dir = File.dirname(full_path)
    FileUtils.mkdir_p(dir)
    File.write(full_path, html)
  end
end
