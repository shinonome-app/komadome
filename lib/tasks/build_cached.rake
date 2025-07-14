# frozen_string_literal: true

namespace :build do
  desc 'Build all pages with smart caching (skip unchanged pages)'
  task all_cached: %i[environment build:clean build:prepare_assets build:copy_zip_files] do
    # ログレベルを一時的に変更
    original_log_level = Rails.logger.level
    Rails.logger.level = ENV.fetch('RAILS_LOG_LEVEL', 'warn').to_sym

    # ActiveRecordのログも抑制
    if defined?(ActiveRecord::Base)
      original_ar_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = Rails.logger
    end

    begin
      # 最適化されたビルドを実行
      orchestrator = BuildOrchestrator.new(
        verbose: true,
        track_usage: ENV['TRACK_USAGE'] != 'false' # デフォルトで有効
      )
      orchestrator.run
    ensure
      # ログレベルを元に戻す
      Rails.logger.level = original_log_level
      ActiveRecord::Base.logger = original_ar_logger if defined?(ActiveRecord::Base) && original_ar_logger
    end
  end

  desc 'Analyze build cache efficiency'
  task analyze_cache: :environment do
    manager = BuildCacheManager.new
    stats = manager.stats

    puts 'Build Cache Analysis'
    puts '=' * 50
    puts "Total pages in cache: #{stats[:total_pages]}"
    puts "Recently built (<24h): #{stats[:recent_builds]}"
    puts "Old pages (>30d): #{stats[:old_pages]}"
    puts "Cache file size: #{(stats[:cache_size] / 1024.0 / 1024.0).round(2)} MB"

    # ページタイプ別の統計
    cache = manager.instance_variable_get(:@cache)
    page_types = Hash.new(0)

    cache.each_key do |path|
      case path
      when /sakuhin_/
        page_types['作品インデックス'] += 1
      when /person\d+\.html/
        page_types['人物詳細'] += 1
      when /card\d+\.html/
        page_types['作品詳細'] += 1
      when /soramoyou/
        page_types['お知らせ'] += 1
      else
        page_types['その他'] += 1
      end
    end

    puts "\nPage type distribution:"
    page_types.each do |type, count|
      percentage = (count.to_f / stats[:total_pages] * 100).round(1)
      puts "  #{type}: #{count} (#{percentage}%)"
    end
  end

  desc 'Clear build cache and force full rebuild'
  task clear_cache: :environment do
    cache_manager = BuildCacheManager.new
    cache_manager.clear
    puts 'Build cache cleared'
  end

  desc 'Show build cache statistics'
  task cache_stats: :environment do
    cache_manager = BuildCacheManager.new
    stats = cache_manager.stats

    puts 'Build cache statistics:'
    puts "  Total cached pages: #{stats[:total_pages]}"
    puts "  Recent builds (< 24h): #{stats[:recent_builds]}"
    puts "  Old pages (> 30d): #{stats[:old_pages]}"
    puts "  Cache file size: #{(stats[:cache_size] / 1024.0).round(1)} KB"
    puts "  Cache file: #{BuildCacheManager::CACHE_FILE}"
  end
end
