# frozen_string_literal: true

# キャッシュを使用したページ生成
class CachedPageGenerator
  def initialize(builder, cache_manager)
    @builder = builder
    @cache = cache_manager
    @skipped = 0
    @built = 0
  end

  # 単一ページを条件付きで生成
  def generate_if_needed(path, dependencies = {})
    if @cache.needs_rebuild?(path, dependencies)
      @builder.build_html(path: path)
      @cache.record_build(path, dependencies)
      @built += 1
      true
    else
      @skipped += 1
      false
    end
  end

  # 複数ページを条件付きで生成
  def generate_batch_if_needed(paths_with_deps)
    paths_to_build = []

    paths_with_deps.each do |path, dependencies|
      if @cache.needs_rebuild?(path, dependencies)
        paths_to_build << path
        @cache.record_build(path, dependencies)
      else
        @skipped += 1
      end
    end

    if paths_to_build.any?
      @builder.build_html(paths: paths_to_build)
      @built += paths_to_build.size
    end

    paths_to_build.size
  end

  # 統計を表示
  def show_stats
    total = @built + @skipped
    skip_rate = total > 0 ? (@skipped.to_f / total * 100).round(1) : 0

    Rails.logger.debug 'Build statistics:'
    Rails.logger.debug { "  Built: #{@built} pages" }
    Rails.logger.debug { "  Skipped: #{@skipped} pages (#{skip_rate}%)" }
    Rails.logger.debug { "  Total: #{total} pages" }
  end

  attr_reader :built, :skipped
end
