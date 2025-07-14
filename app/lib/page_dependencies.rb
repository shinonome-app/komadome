# frozen_string_literal: true

# より正確な依存関係定義
class PageDependencies
  class << self
    # 静的インデックスページ（依存なし）
    def static_index_pages
      {
        'index.html' => { static: true },
        'index_pages/index_top.html' => { static: true },
        'index_pages/index_all.html' => { static: true },
        'index_pages/person_all.html' => { static: true }
      }
    end

    # 作品インデックスページ
    # 特定の頭文字の作品のみに依存
    def work_index_page(kana, published: true)
      {
        models: {
          Work: { title_firstchar: kana, published: published }
        },
        # 関連するモデルも最近更新されたもののみチェック
        related_checks: {
          Person: :recent_only, # 最近更新された人物のみ
          WorkPerson: :recent_only,
          KanaType: :all # マスタデータは全チェック
        }
      }
    end

    # 人物詳細ページ
    # 特定の人物とその作品のみに依存
    def person_page(person_id)
      {
        models: {
          Person: { id: person_id }
        },
        # この人物に関連するレコードのみチェック
        related_models: {
          Work: ->(t_person_id) { Work.joins(:work_people).where(work_people: { person_id: t_person_id }) },
          WorkPerson: { person_id: person_id },
          PersonSite: { person_id: person_id }
        },
        # マスタデータ
        master_data: {
          KanaType: :all,
          Site: :recent_only,
          BasePerson: :recent_only
        }
      }
    end

    # 作品詳細ページ
    # 特定の作品に関連するレコードのみに依存
    def work_detail_page(work_id)
      {
        models: {
          Work: { id: work_id }
        },
        # この作品に直接関連するレコードのみ
        related_models: {
          WorkPerson: { work_id: work_id },
          OriginalBook: { work_id: work_id },
          WorkWorker: { work_id: work_id },
          Workfile: { work_id: work_id },
          WorkSite: { work_id: work_id }
        },
        # 間接的に関連するレコード（JOINで取得）
        indirect_models: {
          Person: ->(t_work_id) { Person.joins(:work_people).where(work_people: { work_id: t_work_id }) },
          Worker: ->(t_work_id) { Worker.joins(:work_workers).where(work_workers: { work_id: t_work_id }) }
        },
        # マスタデータ（変更頻度が低い）
        master_data: {
          Role: :all,
          Booktype: :all,
          WorkerRole: :all,
          Filetype: :all,
          Compresstype: :all,
          Charset: :all,
          FileEncoding: :all,
          Bibclass: :all,
          Site: :recent_only
        }
      }
    end

    # お知らせページ
    def soramoyou_page(year = nil)
      if year
        {
          models: {
            NewsEntry: ->(year) { NewsEntry.where(created_at: Date.new(year)..Date.new(year).end_of_year) }
          }
        }
      else
        {
          models: {
            NewsEntry: {} # 全NewsEntry
          }
        }
      end
    end

    # 新着情報ページ
    def whatsnew_page(year = nil, _page = 1)
      year ? Date.new(year).end_of_year : Time.zone.today

      {
        models: {
          Work: ->(date) { Work.latest_published(until_date: date) }
        },
        # 最近公開された作品の関連データのみ
        related_checks: {
          WorkPerson: :recent_only,
          Person: :recent_only,
          WorkWorker: :recent_only,
          Worker: :recent_only
        }
      }
    end

    # より効率的な依存関係チェックのためのヘルパー
    def should_check_all_records?(check_type)
      check_type == :all
    end

    def recent_check_period
      7.days.ago
    end
  end
end
