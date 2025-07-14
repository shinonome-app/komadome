# frozen_string_literal: true

# ページ生成時に実際に使用されたレコードを追跡
class RecordUsageTracker
  def initialize
    @used_records = Hash.new { |h, k| h[k] = Set.new }
    @tracking_enabled = false
  end

  # トラッキング開始
  def start_tracking
    @used_records.clear
    @tracking_enabled = true
    setup_activerecord_callbacks
  end

  # トラッキング終了
  def stop_tracking
    @tracking_enabled = false
    remove_activerecord_callbacks
    result = @used_records.transform_values(&:to_a)
    @used_records.clear
    result
  end

  # 特定のブロック内でのみトラッキング
  def track
    start_tracking
    yield
  ensure
    stop_tracking
  end

  private

  def setup_activerecord_callbacks
    # ActiveRecordのクエリ実行をフック
    @subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      next unless @tracking_enabled

      event = ActiveSupport::Notifications::Event.new(*args)
      extract_model_and_ids(event)
    end
  end

  def remove_activerecord_callbacks
    ActiveSupport::Notifications.unsubscribe(@subscriber) if @subscriber
  end

  def extract_model_and_ids(event)
    # SQLからモデル名とIDを抽出する簡易パーサー
    sql = event.payload[:sql]

    # SELECT文のみ対象
    return unless sql =~ /SELECT/i

    # テーブル名を抽出
    return unless sql =~ /FROM\s+["`]?(\w+)["`]?/i

    table_name = ::Regexp.last_match(1)
    model_class = table_to_model(table_name)
    return unless model_class

    # WHERE句からIDを抽出
    if sql =~ /WHERE.*["`]?id["`]?\s*=\s*(\d+)/i
      @used_records[model_class.name] << ::Regexp.last_match(1).to_i
    elsif sql =~ /WHERE.*["`]?id["`]?\s+IN\s*\(([^)]+)\)/i
      ids = ::Regexp.last_match(1).split(',').map(&:strip).map(&:to_i)
      @used_records[model_class.name].merge(ids)
    end
  end

  def table_to_model(table_name)
    # テーブル名からモデルクラスを推定
    table_name.classify.constantize
  rescue NameError
    nil
  end
end

# 使用例：
# tracker = RecordUsageTracker.new
# used_records = tracker.track do
#   # ページ生成処理
# end
# => { "Work" => [1, 2, 3], "Person" => [10, 11] }
