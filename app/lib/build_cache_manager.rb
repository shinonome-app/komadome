# frozen_string_literal: true

require 'json'
require 'digest'

# より効率的なキャッシュ管理
class BuildCacheManager
  CACHE_FILE = Rails.root.join('tmp/build_cache_v2.json')

  def initialize
    @cache = load_cache
    @update_times_cache = {} # モデルの更新時刻をキャッシュ
  end

  # ページが再生成必要かチェック（改善版）
  def needs_rebuild?(path, dependencies = {})
    return true unless @cache[path]

    cached_info = @cache[path]
    cached_time = Time.zone.parse(cached_info['built_at'])

    # シンプルな時間ベースのチェック（オプション）
    # 30日以上前のページは無条件で再生成
    return true if cached_time < 30.days.ago

    # 実際に記録されたレコードIDをチェック
    return check_actual_records_updated(cached_info['actual_record_ids'], cached_time) if cached_info['actual_record_ids']

    # 従来の依存関係チェック（フォールバック）
    check_dependencies_updated(dependencies, cached_time)
  end

  # ビルド完了を記録（従来互換）
  def record_build(path, dependencies = {})
    @cache[path] = {
      'built_at' => Time.current.iso8601,
      'dependency_hash' => calculate_dependency_hash(dependencies),
      'dependencies' => dependencies.transform_keys(&:to_s)
    }
  end

  # 実際に使用されたレコードIDを記録する新メソッド
  def record_build_with_actual_records(path, dependencies = {}, actual_record_ids = {})
    @cache[path] = {
      'built_at' => Time.current.iso8601,
      'dependency_hash' => calculate_dependency_hash(dependencies),
      'dependencies' => dependencies.transform_keys(&:to_s),
      'actual_record_ids' => actual_record_ids # 実際に使用したレコードID
    }
  end

  # バッチで更新チェック（効率化）
  def filter_pages_needing_rebuild(pages_with_deps)
    needs_rebuild = []

    # 更新時刻を事前に一括取得
    preload_update_times(pages_with_deps)

    pages_with_deps.each do |path, dependencies|
      needs_rebuild << [path, dependencies] if needs_rebuild?(path, dependencies)
    end

    needs_rebuild
  end

  def save
    FileUtils.mkdir_p(File.dirname(CACHE_FILE))
    File.write(CACHE_FILE, JSON.pretty_generate(@cache))
  end

  def clear
    @cache = {}
    @update_times_cache = {}
    save
  end

  def stats
    total = @cache.size
    recent = @cache.count { |_, info| Time.zone.parse(info['built_at']) > 1.day.ago }
    old = @cache.count { |_, info| Time.zone.parse(info['built_at']) < 30.days.ago }

    {
      total_pages: total,
      recent_builds: recent,
      old_pages: old,
      cache_size: File.exist?(CACHE_FILE) ? File.size(CACHE_FILE) : 0
    }
  end

  private

  def load_cache
    return {} unless File.exist?(CACHE_FILE)

    JSON.parse(File.read(CACHE_FILE))
  rescue JSON::ParserError
    {}
  end

  def calculate_dependency_hash(dependencies)
    Digest::SHA256.hexdigest(dependencies.to_json)
  end

  # 実際のレコードIDベースでチェック
  def check_actual_records_updated(actual_record_ids, cached_time)
    actual_record_ids.each do |model_name, ids|
      next if ids.empty?

      model_class = model_name.to_s.constantize
      # IDリストで絞り込んでチェック（効率的）
      updated_count = model_class.where(id: ids).where('updated_at > ?', cached_time).count
      return true if updated_count > 0
    end

    false
  end

  # 従来の依存関係チェック（改善版）
  def check_dependencies_updated(dependencies, cached_time)
    dependencies.each do |model_name, conditions|
      model_class = model_name.to_s.classify.constantize

      # 空の条件の場合は、最近の更新のみチェック（全レコードではない）
      if conditions.empty?
        last_updated = get_recent_update_time(model_class)
      else
        scope = model_class.where(conditions)
        last_updated = scope.maximum(:updated_at)
      end

      return true if last_updated && last_updated > cached_time
    end

    false
  end

  # 最近の更新時刻を効率的に取得
  def get_recent_update_time(model_class)
    @update_times_cache[model_class.name] ||=
      model_class.where('updated_at > ?', 7.days.ago).maximum(:updated_at)
  end

  # 更新時刻を事前に一括取得
  def preload_update_times(pages_with_deps)
    model_names = pages_with_deps.flat_map { |_, deps| deps.keys }.uniq

    model_names.each do |model_name|
      model_class = model_name.to_s.classify.constantize
      @update_times_cache[model_class.name] ||=
        model_class.where('updated_at > ?', 7.days.ago).maximum(:updated_at)
    end
  end
end
