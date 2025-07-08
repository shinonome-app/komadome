# frozen_string_literal: true

require_relative 'page_generator'
require_relative 'progress_reporter'

# Static page builder - handles file operations and coordinates page generation
class StaticPageBuilder
  attr_reader :target_dir, :rsync_keyfile

  def initialize(target_dir: nil, verbose: true)
    @target_dir = target_dir || Rails.root.join('tmp/build')
    @rsync_keyfile = '/tmp/rsync.key'
    @page_generator = PageGenerator.new(@target_dir)
    @progress_reporter = ProgressReporter.new(verbose: verbose)

    yield self if block_given?
  end

  def copy_precompiled_assets
    Rake::Task['assets:precompile'].invoke
    FileUtils.mkdir_p(@target_dir.join('assets'))
    Rails.public_path.join('assets').children.each do |file|
      FileUtils.cp_r(Rails.public_path.join('assets', file), @target_dir.join('assets'))
    end
  end

  def copy_public_images
    # /images
    FileUtils.mkdir_p(@target_dir.join('images'))
    FileUtils.cp_r(Rails.public_path.join('images'), @target_dir)

    # /cards/images
    FileUtils.mkdir_p(@target_dir.join('cards/images'))
    FileUtils.cp_r(Rails.public_path.join('cards/images'), @target_dir.join('cards'))
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

  # Generate HTML pages - supports both single path and array of paths
  def build_html(path: nil, paths: nil, verbose: nil)
    # Update verbosity if specified
    @progress_reporter = ProgressReporter.new(verbose: verbose) if verbose != @progress_reporter.instance_variable_get(:@verbose) && !verbose.nil?

    # Handle single path (backward compatibility)
    if path
      full_path = @page_generator.generate(path)
      @progress_reporter.log_generation(full_path)
      return full_path
    end

    # Handle multiple paths (batch processing)
    return { success: 0, failed: 0, errors: [] } if paths.blank?

    total = paths.size
    @progress_reporter.reset_stats

    @progress_reporter.log_batch_start(total, 1) # Sequential processing
    start_time = Time.current

    paths.each_with_index do |batch_path, index|
      full_path = @page_generator.generate(batch_path)
      @progress_reporter.log_generation(full_path)
      @progress_reporter.record_success
      @progress_reporter.show_progress(index + 1, total, start_time)
    rescue StandardError => e
      error_msg = "#{batch_path}: #{e.message}"
      @progress_reporter.record_failure(error_msg)
    end

    elapsed = Time.current - start_time
    @progress_reporter.log_batch_complete(elapsed)
    @progress_reporter.stats
  end

  def create_rsync_keyfile(data)
    File.write(@rsync_keyfile, data.gsub('@NL@', "\n"))
    FileUtils.chmod(0o600, @rsync_keyfile)
  end
end
