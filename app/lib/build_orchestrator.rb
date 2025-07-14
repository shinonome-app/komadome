# frozen_string_literal: true

# ビルドオーケストレータ
class BuildOrchestrator
  def initialize(verbose: true, track_usage: true)
    @verbose = verbose
    @track_usage = track_usage
    @cache_manager = BuildCacheManager.new
    @usage_tracker = RecordUsageTracker.new if @track_usage
    @stats = { built: 0, skipped: 0, time_saved: 0 }
  end

  def run
    log 'Optimized build starting...'
    show_cache_stats

    StaticPageBuilder.new do |builder|
      # 1. 静的ページ（30日に1回程度の更新で十分）
      build_static_pages_if_needed(builder)

      # 2. 動的ページを効率的にビルド
      build_dynamic_pages_efficiently(builder)
    end

    @cache_manager.save
    show_final_stats
  end

  private

  def build_static_pages_if_needed(builder)
    log "\nProcessing static pages..."

    PageDependencies.static_index_pages.each_key do |path|
      # 静的ページは30日ごとに更新
      cached_info = @cache_manager.instance_variable_get(:@cache)[path]
      if cached_info.nil? || Time.zone.parse(cached_info['built_at']) < 30.days.ago
        builder.build_html(path: path)
        @cache_manager.record_build(path, { static: true })
        @stats[:built] += 1
        log "  Built: #{path} (static page refresh)"
      else
        @stats[:skipped] += 1
        @stats[:time_saved] += 0.5 # 静的ページの生成時間概算
      end
    end
  end

  def build_dynamic_pages_efficiently(builder)
    # 更新されたモデルを事前にチェック
    recently_updated = check_recent_updates

    # 定期的に公開される作品もチェック
    check_scheduled_publications(recently_updated)

    if recently_updated.empty?
      log "\nNo recent updates found. Skipping all dynamic pages."
      @stats[:skipped] += estimate_total_dynamic_pages
      @stats[:time_saved] += estimate_total_build_time
      return
    end

    log "\nRecent updates found in: #{recently_updated.keys.join(', ')}"

    # 更新があったモデルに関連するページのみビルド
    build_affected_pages(builder, recently_updated)
  end

  def check_recent_updates
    updated = {}
    check_period = 7.days.ago

    # 主要モデルの更新をチェック
    %w[Work Person NewsEntry Worker Site].each do |model_name|
      model_class = model_name.constantize
      last_update = model_class.where('updated_at > ?', check_period).maximum(:updated_at)
      updated[model_name] = last_update if last_update
    end

    # 中間テーブルの更新もチェック
    %w[WorkPerson WorkWorker PersonSite WorkSite BasePerson OriginalBook Workfile].each do |model_name|
      model_class = model_name.constantize
      last_update = model_class.where('updated_at > ?', check_period).maximum(:updated_at)
      updated[model_name] = last_update if last_update
    end

    updated
  end

  def check_scheduled_publications(recently_updated)
    # 本日公開予定の作品をチェック
    today = Time.zone.today
    newly_published = Work.where(work_status_id: 1, started_on: today)

    return unless newly_published.exists?

    log "\nFound #{newly_published.count} newly published works today"
    recently_updated['Work'] = [recently_updated['Work'], Time.current].compact.max
  end

  def build_affected_pages(builder, recently_updated)
    # 作品が更新された場合
    build_work_related_pages(builder, recently_updated['Work']) if recently_updated['Work']

    # 人物が更新された場合
    build_person_related_pages(builder, recently_updated['Person']) if recently_updated['Person']

    # お知らせが更新された場合
    build_news_pages(builder) if recently_updated['NewsEntry']

    # 中間テーブルが更新された場合の処理
    handle_join_table_updates(builder, recently_updated)
  end

  def build_person_related_pages(builder, last_update)
    log "\nBuilding person-related pages..."

    # 更新された人物を取得
    updated_people = Person.where('updated_at > ?', last_update - 1.hour)

    return if updated_people.empty?

    # 更新された人物のページを再生成
    updated_people.find_each do |person|
      path = "index_pages/person#{person.id}.html"

      if @track_usage
        used_records = @usage_tracker.track do
          builder.build_html(path: path)
        end
        @cache_manager.record_build_with_actual_records(path,
                                                        PageDependencies.person_page(person.id),
                                                        used_records)
      else
        builder.build_html(path: path)
        @cache_manager.record_build(path, PageDependencies.person_page(person.id))
      end

      @stats[:built] += 1
      log "  Built: #{path}"
    end
  end

  def build_work_related_pages(builder, last_update)
    log "\nBuilding work-related pages..."

    # 更新された作品、または新しく公開された作品を取得
    updated_works = Work.where(
      'updated_at > ? OR (work_status_id = 1 AND started_on > ?)',
      last_update - 1.hour,
      last_update - 1.hour
    )

    # 影響を受ける頭文字を特定
    # sortkey の最初の文字を取得し、どのかなグループに属するか判定
    affected_kana_syms = Set.new

    updated_works.pluck(:sortkey).each do |sortkey|
      next if sortkey.blank?

      first_char = sortkey[0]
      # 各かなグループをチェックして、該当するシンボルを見つける
      Kana.each_sym_and_char do |sym, kana_char|
        if kana_char == first_char || (sym == :zz && !first_char.match?(/[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]/))
          affected_kana_syms.add(sym)
          break
        end
      end
    end

    # 該当する作品インデックスのみ再生成
    affected_kana_syms.each do |sym|
      kana = Kana::ROMA2KANA[sym]
      build_work_index_for_kana(builder, sym, kana)
    end

    # 更新された作品の詳細ページ
    build_updated_work_details(builder, updated_works)

    # 更新された作品に関連する著者ページ
    build_affected_person_pages(builder, updated_works)
  end

  def build_work_index_for_kana(builder, id, kana)
    works = Work.published.with_title_firstchar(kana)
    total_pages = (works.count / 50.0).ceil

    (1..total_pages).each do |page|
      path = "index_pages/sakuhin_#{id}#{page}.html"

      if @track_usage
        used_records = @usage_tracker.track do
          builder.build_html(path: path)
        end
        @cache_manager.record_build_with_actual_records(path,
                                                        PageDependencies.work_index_page(kana),
                                                        used_records)
      else
        builder.build_html(path: path)
        @cache_manager.record_build(path, PageDependencies.work_index_page(kana))
      end

      @stats[:built] += 1
      log "  Built: #{path}"
    end
  end

  def build_updated_work_details(builder, updated_works)
    log "  Building #{updated_works.count} updated work detail pages..."

    url = Rails.application.routes.url_helpers

    updated_works.includes(work_people: :person).find_each do |work|
      path = url.card_path(
        person_id: work.card_person_id,
        card_id: work.id,
        format: :html
      )

      if @track_usage
        used_records = @usage_tracker.track do
          builder.build_html(path: path)
        end
        @cache_manager.record_build_with_actual_records(path,
                                                        PageDependencies.work_detail_page(work.id),
                                                        used_records)
      else
        builder.build_html(path: path)
        @cache_manager.record_build(path, PageDependencies.work_detail_page(work.id))
      end

      @stats[:built] += 1
    end
  end

  def build_affected_person_pages(builder, updated_works)
    # 更新された作品に関連する著者を収集
    affected_person_ids = Set.new

    updated_works.includes(work_people: :person).find_each do |work|
      work.work_people.where(role_id: 1).find_each do |work_person|
        affected_person_ids.add(work_person.person_id)
      end
    end

    return if affected_person_ids.empty?

    log "  Building #{affected_person_ids.size} affected person pages..."

    # 影響を受ける著者のページを再生成
    Person.where(id: affected_person_ids.to_a).find_each do |person|
      path = "index_pages/person#{person.id}.html"

      if @track_usage
        used_records = @usage_tracker.track do
          builder.build_html(path: path)
        end
        @cache_manager.record_build_with_actual_records(path,
                                                        PageDependencies.person_page(person.id),
                                                        used_records)
      else
        builder.build_html(path: path)
        @cache_manager.record_build(path, PageDependencies.person_page(person.id))
      end

      @stats[:built] += 1
      log "  Built: #{path}"
    end
  end

  def build_news_pages(builder)
    log "\nBuilding news pages..."

    # お知らせ一覧ページ（年別）
    current_year = Time.zone.now.year
    (2015..current_year).each do |year|
      path = "soramoyou#{year}.html"

      if @track_usage
        used_records = @usage_tracker.track do
          builder.build_html(path: path)
        end
        @cache_manager.record_build_with_actual_records(path,
                                                        PageDependencies.soramoyou_page(year),
                                                        used_records)
      else
        builder.build_html(path: path)
        @cache_manager.record_build(path, PageDependencies.soramoyou_page(year))
      end

      @stats[:built] += 1
      log "  Built: #{path}"
    end

    # 新着情報ページ
    path = 'soramoyou_new.html'
    if @track_usage
      used_records = @usage_tracker.track do
        builder.build_html(path: path)
      end
      @cache_manager.record_build_with_actual_records(path,
                                                      PageDependencies.soramoyou_page,
                                                      used_records)
    else
      builder.build_html(path: path)
      @cache_manager.record_build(path, PageDependencies.soramoyou_page)
    end

    @stats[:built] += 1
    log "  Built: #{path}"
  end

  def handle_join_table_updates(builder, recently_updated)
    # WorkPersonが更新された場合、関連する作品と人物のページを更新
    if recently_updated['WorkPerson']
      log "\nHandling WorkPerson updates..."
      affected_work_ids = WorkPerson.where('updated_at > ?', recently_updated['WorkPerson'] - 1.hour).pluck(:work_id).uniq
      WorkPerson.where('updated_at > ?', recently_updated['WorkPerson'] - 1.hour).pluck(:person_id).uniq

      # 影響を受ける作品の詳細ページを更新
      build_updated_work_details(builder, Work.where(id: affected_work_ids))

      # 影響を受ける人物のページを更新
      build_affected_person_pages(builder, Work.where(id: affected_work_ids))
    end

    # WorkWorkerが更新された場合
    if recently_updated['WorkWorker']
      log "\nHandling WorkWorker updates..."
      affected_work_ids = WorkWorker.where('updated_at > ?', recently_updated['WorkWorker'] - 1.hour).pluck(:work_id).uniq
      build_updated_work_details(builder, Work.where(id: affected_work_ids))
    end

    # OriginalBookやWorkfileが更新された場合
    %w[OriginalBook Workfile].each do |model_name|
      next unless recently_updated[model_name]

      log "\nHandling #{model_name} updates..."
      model_class = model_name.constantize
      affected_work_ids = model_class.where('updated_at > ?', recently_updated[model_name] - 1.hour).pluck(:work_id).uniq
      build_updated_work_details(builder, Work.where(id: affected_work_ids))
    end

    # BasePersonが更新された場合
    return unless recently_updated['BasePerson']

    log "\nHandling BasePerson updates..."
    affected_person_ids = BasePerson.where('updated_at > ?', recently_updated['BasePerson'] - 1.hour)
                                    .pluck(:person_id, :original_person_id).flatten.uniq

    Person.where(id: affected_person_ids).find_each do |person|
      path = "index_pages/person#{person.id}.html"

      builder.build_html(path: path)
      @cache_manager.record_build(path, PageDependencies.person_page(person.id))
      @stats[:built] += 1
      log "  Built: #{path}"
    end
  end

  def estimate_total_dynamic_pages
    Work.published.count + Person.count + 1000 # 概算
  end

  def estimate_total_build_time
    estimate_total_dynamic_pages * 0.1 # 1ページ0.1秒と仮定
  end

  def show_cache_stats
    stats = @cache_manager.stats
    log "\nCache statistics:"
    log "  Total cached: #{stats[:total_pages]} pages"
    log "  Recent builds: #{stats[:recent_builds]} pages"
    log "  Old pages (>30d): #{stats[:old_pages]} pages"
  end

  def show_final_stats
    log "\n#{'=' * 50}"
    log 'Build complete:'
    log "  Pages built: #{@stats[:built]}"
    log "  Pages skipped: #{@stats[:skipped]}"
    log "  Estimated time saved: #{@stats[:time_saved].round(1)} seconds"

    efficiency = @stats[:skipped].to_f / (@stats[:built] + @stats[:skipped]) * 100
    log "  Cache efficiency: #{efficiency.round(1)}%"
  end

  def log(message)
    Rails.logger.debug message if @verbose
  end
end
