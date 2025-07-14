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
    def work_index_page(_kana, published: true) # rubocop:disable Lint/UnusedMethodArgument
      # publishedパラメータは将来の公開/非公開作品の分離処理用に保持
      {
        models: {
          # 作品インデックスには作品情報と著者情報が表示される
          Work: {},
          Person: {},
          WorkPerson: {},
          Role: {} # 翻訳者等の役割表示
        }
      }
    end

    # 人物詳細ページ
    # 特定の人物とその作品のみに依存
    def person_page(person_id)
      {
        models: {
          Person: { id: person_id },
          WorkPerson: { person_id: person_id },
          PersonSite: { person_id: person_id },
          BasePerson: { person_id: person_id },
          # 作品情報（人物ページに表示される）
          Work: {}, # WorkPersonを通じて関連
          # マスタデータ
          Site: {},
          Role: {},
          KanaType: {}
        }
      }
    end

    # 作品詳細ページ
    # 特定の作品に関連するレコードのみに依存
    def work_detail_page(work_id)
      {
        models: {
          Work: { id: work_id },
          WorkPerson: { work_id: work_id },
          OriginalBook: { work_id: work_id },
          WorkWorker: { work_id: work_id },
          Workfile: { work_id: work_id },
          WorkSite: { work_id: work_id },
          # 関連する人物・労働者（作品に紐づく）
          Person: {},  # WorkPersonを通じて関連
          Worker: {},  # WorkWorkerを通じて関連
          # マスタデータ（表示に必要）
          Site: {},
          Role: {},
          WorkerRole: {},
          Booktype: {},
          Filetype: {},
          Compresstype: {},
          Charset: {},
          FileEncoding: {}
        }
      }
    end

    # お知らせページ
    def soramoyou_page(year = nil)
      if year
        {
          models: {
            NewsEntry: { published_on: Date.new(year.to_i)..Date.new(year.to_i).end_of_year }
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
    def whatsnew_page(_year = nil, _page = 1)
      {
        models: {
          # 新着作品の表示には作品情報と著者情報が必要
          Work: {},
          Person: {},
          WorkPerson: {},
          # 入力者・校正者情報も表示される
          Worker: {},
          WorkWorker: {},
          WorkerRole: {}
        }
      }
    end
  end
end
