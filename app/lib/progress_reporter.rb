# frozen_string_literal: true

# Handles progress reporting and statistics for page generation
class ProgressReporter
  attr_reader :stats

  def initialize(verbose: true)
    @verbose = verbose
    @stats = { success: 0, failed: 0, errors: [] }
    @mutex = Mutex.new
  end

  def reset_stats
    @mutex.synchronize do
      @stats = { success: 0, failed: 0, errors: [] }
    end
  end

  def record_success
    @mutex.synchronize { @stats[:success] += 1 }
  end

  def record_failure(error_message)
    @mutex.synchronize do
      @stats[:failed] += 1
      @stats[:errors] << error_message
    end
  end

  def log_generation(path)
    log_info("Generate #{path}") if @verbose
  end

  def log_batch_start(total, concurrency)
    log_info("Starting batch generation of #{total} pages with #{concurrency} workers")
  end

  def log_batch_complete(elapsed)
    log_info("Batch generation completed in #{elapsed.round(2)}s")
    log_info("Results: #{@stats[:success]} successful, #{@stats[:failed]} failed")

    return unless @stats[:errors].any?

    log_error('Failed pages:')
    @stats[:errors].each { |error| log_error("  #{error}") }
  end

  def show_progress(processed, total, start_time)
    return unless @verbose && (processed % 10 == 0 || processed == total)

    percentage = (processed.to_f / total * 100).round(1)
    elapsed = Time.current - start_time
    rate = processed / elapsed
    eta = (total - processed) / rate

    log_info("[PROGRESS] #{processed}/#{total} (#{percentage}%) | " \
             "Rate: #{rate.round(1)}/s | ETA: #{eta.round(0)}s")
  end

  private

  def log_info(message)
    puts "[INFO] #{timestamp} #{message}" # rubocop:disable Rails/Output
  end

  def log_error(message)
    puts "[ERROR] #{timestamp} #{message}" # rubocop:disable Rails/Output
  end

  def timestamp
    Time.current.strftime('%H:%M:%S')
  end
end
