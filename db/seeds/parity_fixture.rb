# frozen_string_literal: true

# Parity fixture: minimal edge-case dataset for komadome ⇄ komadome-rs parity testing.
#
# Usage: PARITY_FIXTURE=1 bundle exec rake db:seed
# This loads master tables from seeds.rb first, then inserts fixture data here.
#
# See: komadome-rs/docs/parity-fixture-plan.md

module ParityFixture # rubocop:disable Metrics/ModuleLength
  # Master table IDs (must match seeds.rb)
  KANA_TYPE_ID = 1
  CHARSET_ID = 1        # JIS X 0208
  FILE_ENCODING_ID = 1  # Shift_JIS
  COMPRESSTYPE_ID = 1    # 圧縮なし
  FILETYPE_ID = 2        # テキストファイル(ルビなし)
  BOOKTYPE_ID = 1        # 底本
  ROLE_AUTHOR = 1
  ROLE_TRANSLATOR = 2
  ROLE_EDITOR = 3
  WORKER_ROLE_INPUT = 1
  WORKER_ROLE_PROOFREAD = 2

  # Persons (20 people covering edge cases)
  PERSONS = [
    # 101: normal case (last + first + en)
    { id: 101, last_name: '太宰', last_name_kana: 'だざい', last_name_en: 'Dazai',
      first_name: '治', first_name_kana: 'おさむ', first_name_en: 'Osamu',
      copyright_flag: true, sortkey: 'だざい', sortkey2: 'おさむ' },
    # 102: last_name only (first_name=NULL)
    { id: 102, last_name: '紫式部', last_name_kana: 'むらさきしきぶ', last_name_en: 'Murasaki',
      first_name: nil, first_name_kana: nil, first_name_en: nil,
      copyright_flag: false, sortkey: 'むらさきしきぶ', sortkey2: nil },
    # 103: last_name_en only (no first_name_en)
    { id: 103, last_name: '芥川', last_name_kana: 'あくたがわ', last_name_en: 'Akutagawa',
      first_name: '龍之介', first_name_kana: 'りゅうのすけ', first_name_en: nil,
      copyright_flag: false, sortkey: 'あくたがわ', sortkey2: 'りゅうのすけ' },
    # 104: non-kana sortkey (numeric start → "zz" partition)
    { id: 104, last_name: '100年太郎', last_name_kana: 'ひゃくねんたろう', last_name_en: nil,
      first_name: nil, first_name_kana: nil, first_name_en: nil,
      copyright_flag: false, sortkey: '100ねんたろう', sortkey2: nil },
    # 105: katakana name
    { id: 105, last_name: 'タロウ', last_name_kana: 'たろう', last_name_en: 'TAROU',
      first_name: 'ヤマダ', first_name_kana: 'やまだ', first_name_en: 'YAMADA',
      copyright_flag: false, sortkey: 'たろう', sortkey2: 'やまだ' },
    # 106: copyright_flag=true
    { id: 106, last_name: '村上', last_name_kana: 'むらかみ', last_name_en: 'Murakami',
      first_name: '春樹', first_name_kana: 'はるき', first_name_en: 'Haruki',
      copyright_flag: true, sortkey: 'むらかみ', sortkey2: 'はるき' },
    # 107: has unpublished works
    { id: 107, last_name: '夏目', last_name_kana: 'なつめ', last_name_en: 'Natsume',
      first_name: '漱石', first_name_kana: 'そうせき', first_name_en: 'Soseki',
      copyright_flag: false, sortkey: 'なつめ', sortkey2: 'そうせき' },
    # 108: multiple works
    { id: 108, last_name: '森', last_name_kana: 'もり', last_name_en: 'Mori',
      first_name: '鴎外', first_name_kana: 'おうがい', first_name_en: 'Ogai',
      copyright_flag: false, sortkey: 'もり', sortkey2: 'おうがい' },
    # 109: has related sites
    { id: 109, last_name: '宮沢', last_name_kana: 'みやざわ', last_name_en: 'Miyazawa',
      first_name: '賢治', first_name_kana: 'けんじ', first_name_en: 'Kenji',
      copyright_flag: false, sortkey: 'みやざわ', sortkey2: 'けんじ' },
    # 110: has base_person (alias)
    { id: 110, last_name: '伊藤', last_name_kana: 'いとう', last_name_en: 'Ito',
      first_name: '六郎', first_name_kana: 'ろくろう', first_name_en: 'Rokuro',
      copyright_flag: false, sortkey: 'いとう', sortkey2: 'ろくろう' },
    # 111: person with description and URL
    { id: 111, last_name: '坂口', last_name_kana: 'さかぐち', last_name_en: 'Sakaguchi',
      first_name: '安吾', first_name_kana: 'あんご', first_name_en: 'Ango',
      copyright_flag: false, sortkey: 'さかぐち', sortkey2: 'あんご',
      description: '日本の小説家・評論家', url: 'https://example.com/sakaguchi' },
    # 112: person with born_on/died_on
    { id: 112, last_name: '泉', last_name_kana: 'いずみ', last_name_en: 'Izumi',
      first_name: '鏡花', first_name_kana: 'きょうか', first_name_en: 'Kyoka',
      copyright_flag: false, sortkey: 'いずみ', sortkey2: 'きょうか',
      born_on: '1873-11-04', died_on: '1939-09-07' },
    # 113: person with first_name only (no last_name - edge case)
    { id: 113, last_name: 'anonymous', last_name_kana: 'とくめい', last_name_en: 'Anonymous',
      first_name: '作者', first_name_kana: 'さくしゃ', first_name_en: 'Author',
      copyright_flag: false, sortkey: 'とくめい', sortkey2: 'さくしゃ' },
    # 114: person with very long name
    { id: 114, last_name: '吉川', last_name_kana: 'よしかわ', last_name_en: 'Yoshikawa',
      first_name: '英治', first_name_kana: 'えいじ', first_name_en: 'Eiji',
      copyright_flag: false, sortkey: 'よしかわ', sortkey2: 'えいじ' },
    # 115: person for WIP works (list_inp)
    { id: 115, last_name: '菊池', last_name_kana: 'きくち', last_name_en: 'Kikuchi',
      first_name: '寛', first_name_kana: 'かん', first_name_en: 'Kan',
      copyright_flag: false, sortkey: 'きくち', sortkey2: 'かん' },
    # 116: person for whatsnew year boundary
    { id: 116, last_name: '志賀', last_name_kana: 'しが', last_name_en: 'Shiga',
      first_name: '直哉', first_name_kana: 'なおや', first_name_en: 'Naoya',
      copyright_flag: false, sortkey: 'しが', sortkey2: 'なおや' },
    # 117: person for person_all index
    { id: 117, last_name: '横光', last_name_kana: 'よこみつ', last_name_en: 'Yokomitsu',
      first_name: '利一', first_name_kana: 'りいち', first_name_en: 'Riichi',
      copyright_flag: false, sortkey: 'よこみつ', sortkey2: 'りいち' },
    # 118: person with only unpublished works
    { id: 118, last_name: '梶井', last_name_kana: 'かじい', last_name_en: 'Kajii',
      first_name: '基次郎', first_name_kana: 'もとじろう', first_name_en: 'Motojiro',
      copyright_flag: false, sortkey: 'かじい', sortkey2: 'もとじろう' },
    # 119: person for soramoyou
    { id: 119, last_name: '中島', last_name_kana: 'なかじま', last_name_en: 'Nakajima',
      first_name: '敦', first_name_kana: 'あつし', first_name_en: 'Atsushi',
      copyright_flag: false, sortkey: 'なかじま', sortkey2: 'あつし' },
    # 120: person for kana boundary (あ行)
    { id: 120, last_name: 'あ行太郎', last_name_kana: 'あぎょうたろう', last_name_en: 'Agyo',
      first_name: 'テスト', first_name_kana: 'てすと', first_name_en: 'Test',
      copyright_flag: false, sortkey: 'あぎょうたろう', sortkey2: 'てすと' },
    # 201: 作品を持たない人物（空の人物）
    { id: 201, last_name: '空人物', last_name_kana: 'からじんぶつ', last_name_en: 'Empty',
      first_name: 'テスト', first_name_kana: 'てすと', first_name_en: 'Test',
      copyright_flag: false, sortkey: 'からじんぶつ', sortkey2: 'てすと' },
    # 202: HTML特殊文字を含む名前
    { id: 202, last_name: '山田<&>', last_name_kana: 'やまだ', last_name_en: 'Yamada&lt;&gt;',
      first_name: '風太郎', first_name_kana: 'ふうたろう', first_name_en: 'Futaro',
      copyright_flag: false, sortkey: 'やまだ', sortkey2: 'ふうたろう' }
  ].freeze

  # Works (30 works covering edge cases)
  WORKS = [
    # 1001-1005: basic published works with different authors
    { id: 1001, title: '雪の早晨', title_kana: 'ゆきのあした',
      work_status_id: 1, started_on: '2020-01-01', copyright_flag: false,
      sortkey: 'ゆきのあした', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1002, title: '春の夢', title_kana: 'はるのゆめ',
      subtitle: '子供の頃の記憶', subtitle_kana: 'こどものころのきおく',
      work_status_id: 1, started_on: '2020-02-01', copyright_flag: false,
      sortkey: 'はるのゆめ', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1003, title: '夏の空', title_kana: 'なつのそら',
      work_status_id: 1, started_on: '2020-03-01', copyright_flag: false,
      sortkey: 'なつのそら', kana_type_id: KANA_TYPE_ID, user_id: 1,
      note: '<div id="link"><script src="link.js"></script></div>本文テキスト' },
    { id: 1004, title: '秋の色', title_kana: 'あきのいろ',
      work_status_id: 1, started_on: '2099-12-31', copyright_flag: false,
      sortkey: 'あきのいろ', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1005, title: '冬の風', title_kana: 'ふゆのかぜ',
      work_status_id: 11, started_on: '2020-05-01', copyright_flag: false,
      sortkey: 'ふゆのかぜ', kana_type_id: KANA_TYPE_ID, user_id: 1 },

    # 1006-1010: various features
    { id: 1006, title: '星の歌', title_kana: 'ほしのうた',
      collection: '星の歌集', collection_kana: 'ほしのうたしゅう',
      work_status_id: 1, started_on: '2020-06-01', copyright_flag: false,
      sortkey: 'ほしのうた', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1007, title: '月の光', title_kana: 'つきのひかり',
      original_title: 'Moon Light',
      work_status_id: 1, started_on: '2020-07-01', copyright_flag: true,
      sortkey: 'つきのひかり', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1008, title: '★ 特別作品', title_kana: '★とくべつさくひん',
      work_status_id: 1, started_on: '2020-08-01', copyright_flag: false,
      sortkey: '★とくべつさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1009, title: 'テスト作品', title_kana: 'テストさくひん',
      work_status_id: 1, started_on: '2020-09-01', copyright_flag: false,
      sortkey: 'てすとさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1010, title: '共同作品', title_kana: 'きょうどうさくひん',
      work_status_id: 1, started_on: '2020-10-01', copyright_flag: false,
      sortkey: 'きょうどうさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },

    # 1011-1015: more edge cases
    { id: 1011, title: '翻訳作品', title_kana: 'ほんやくさくひん',
      work_status_id: 1, started_on: '2020-11-01', copyright_flag: false,
      sortkey: 'ほんやくさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1012, title: 'サイト作品', title_kana: 'サイトさくひん',
      work_status_id: 1, started_on: '2020-12-01', copyright_flag: false,
      sortkey: 'サイトさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1013, title: '著作権あり', title_kana: 'ちょさくけんあり',
      work_status_id: 1, started_on: '2021-01-01', copyright_flag: true,
      sortkey: 'ちょさくけんあり', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1014, title: '未公開作品', title_kana: 'みこうかいさくひん',
      work_status_id: 3, started_on: '2021-02-01', copyright_flag: false,
      sortkey: 'みこうかいさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1015, title: '追加作品', title_kana: 'ついかさくひん',
      work_status_id: 1, started_on: '2021-03-01', copyright_flag: false,
      sortkey: 'ついかさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },

    # 1016-1020: kana boundary works for index pagination
    { id: 1016, title: 'か行作品1', title_kana: 'かぎょうさくひん1',
      work_status_id: 1, started_on: '2021-04-01', copyright_flag: false,
      sortkey: 'かぎょうさくひん1', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1017, title: 'か行作品2', title_kana: 'かぎょうさくひん2',
      work_status_id: 1, started_on: '2021-05-01', copyright_flag: false,
      sortkey: 'かぎょうさくひん2', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1018, title: 'さ行作品', title_kana: 'さぎょうさくひん',
      work_status_id: 1, started_on: '2021-06-01', copyright_flag: false,
      sortkey: 'さぎょうさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1019, title: 'た行作品', title_kana: 'たぎょうさくひん',
      work_status_id: 1, started_on: '2021-07-01', copyright_flag: false,
      sortkey: 'たぎょうさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1020, title: 'な行作品', title_kana: 'なぎょうさくひん',
      work_status_id: 1, started_on: '2021-08-01', copyright_flag: false,
      sortkey: 'なぎょうさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },

    # 1021-1025: more unpublished/WIP works
    { id: 1021, title: '校正待ち作品', title_kana: 'こうせいまちさくひん',
      work_status_id: 5, started_on: '2021-09-01', copyright_flag: false,
      sortkey: 'こうせいまちさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1022, title: '翻訳中作品', title_kana: 'ほんやくちゅうさくひん',
      work_status_id: 11, started_on: '2021-10-01', copyright_flag: false,
      sortkey: 'ほんやくちゅうさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1023, title: '校了作品', title_kana: 'こうりょうさくひん',
      work_status_id: 10, started_on: '2021-11-01', copyright_flag: false,
      sortkey: 'こうりょうさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1024, title: '入力予約作品', title_kana: 'にゅうりょくよやくさくひん',
      work_status_id: 4, started_on: '2021-12-01', copyright_flag: false,
      sortkey: 'にゅうりょくよやくさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1025, title: '校正中作品', title_kana: 'こうせいちゅうさくひん',
      work_status_id: 9, started_on: '2022-01-01', copyright_flag: false,
      sortkey: 'こうせいちゅうさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },

    # 1026-1030: year boundary works for whatsnew
    { id: 1026, title: '昨年の作品', title_kana: 'きょねんのさくひん',
      work_status_id: 1, started_on: '2025-01-01', copyright_flag: false,
      sortkey: 'きょねんのさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1027, title: '今年の作品', title_kana: 'ことしのさくひん',
      work_status_id: 1, started_on: '2026-01-01', copyright_flag: false,
      sortkey: 'ことしのさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1028, title: '来年の作品', title_kana: 'らいねんのさくひん',
      work_status_id: 1, started_on: '2027-01-01', copyright_flag: false,
      sortkey: 'らいねんのさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1029, title: '古い作品', title_kana: 'ふるいさくひん',
      work_status_id: 1, started_on: '2000-01-01', copyright_flag: false,
      sortkey: 'ふるいさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    { id: 1030, title: 'とても古い作品', title_kana: 'とてもふるいさくひん',
      work_status_id: 1, started_on: '1998-01-01', copyright_flag: false,
      sortkey: 'とてもふるいさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },

    # 2001: 著者なし（person_id=0）の作品 — cards.rs でスキップされる
    { id: 2001, title: '著者不明作品', title_kana: 'ちょしゃふめいさくひん',
      work_status_id: 1, started_on: '2020-01-01', copyright_flag: false,
      sortkey: 'ちょしゃふめいさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 },
    # 2002: HTML特殊文字を含むタイトル — エスケープ処理の確認
    { id: 2002, title: 'テスト<&>"\'作品', title_kana: 'てすとさくひん',
      work_status_id: 1, started_on: '2020-02-01', copyright_flag: false,
      sortkey: 'てすとさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1,
      note: '<script>alert("XSS")</script>本文' },
    # 2003: 空フィールド — subtitle 空文字、note なし
    { id: 2003, title: '空フィールド作品', title_kana: 'くうふぃーるどさくひん',
      subtitle: '', subtitle_kana: '',
      work_status_id: 1, started_on: '2020-03-01', copyright_flag: false,
      sortkey: 'くうふぃーるどさくひん', kana_type_id: KANA_TYPE_ID, user_id: 1 }
  ].freeze

  # WorkPeople (work-person relationships with various roles)
  WORK_PEOPLE = [
    # Single author works
    { work_id: 1001, person_id: 101, role_id: ROLE_AUTHOR },
    { work_id: 1002, person_id: 102, role_id: ROLE_AUTHOR },
    { work_id: 1003, person_id: 103, role_id: ROLE_AUTHOR },
    { work_id: 1004, person_id: 101, role_id: ROLE_AUTHOR },
    { work_id: 1005, person_id: 107, role_id: ROLE_AUTHOR },
    { work_id: 1006, person_id: 104, role_id: ROLE_AUTHOR },
    { work_id: 1007, person_id: 105, role_id: ROLE_AUTHOR },
    { work_id: 1008, person_id: 106, role_id: ROLE_AUTHOR },
    { work_id: 1009, person_id: 101, role_id: ROLE_AUTHOR },

    # Multiple authors
    { work_id: 1010, person_id: 108, role_id: ROLE_AUTHOR },
    { work_id: 1010, person_id: 109, role_id: ROLE_AUTHOR },

    # Author + translator
    { work_id: 1011, person_id: 110, role_id: ROLE_AUTHOR },
    { work_id: 1011, person_id: 101, role_id: ROLE_TRANSLATOR },

    # Author + editor
    { work_id: 1012, person_id: 109, role_id: ROLE_AUTHOR },
    { work_id: 1012, person_id: 108, role_id: ROLE_EDITOR },

    # Copyright works
    { work_id: 1013, person_id: 106, role_id: ROLE_AUTHOR },

    # Unpublished works
    { work_id: 1014, person_id: 107, role_id: ROLE_AUTHOR },
    { work_id: 1015, person_id: 108, role_id: ROLE_AUTHOR },
    { work_id: 1021, person_id: 115, role_id: ROLE_AUTHOR },
    { work_id: 1022, person_id: 115, role_id: ROLE_AUTHOR },
    { work_id: 1023, person_id: 115, role_id: ROLE_AUTHOR },
    { work_id: 1024, person_id: 118, role_id: ROLE_AUTHOR },
    { work_id: 1025, person_id: 118, role_id: ROLE_AUTHOR },

    # Kana boundary works
    { work_id: 1016, person_id: 120, role_id: ROLE_AUTHOR },
    { work_id: 1017, person_id: 120, role_id: ROLE_AUTHOR },
    { work_id: 1018, person_id: 111, role_id: ROLE_AUTHOR },
    { work_id: 1019, person_id: 112, role_id: ROLE_AUTHOR },
    { work_id: 1020, person_id: 113, role_id: ROLE_AUTHOR },

    # Year boundary works
    { work_id: 1026, person_id: 116, role_id: ROLE_AUTHOR },
    { work_id: 1027, person_id: 116, role_id: ROLE_AUTHOR },
    { work_id: 1028, person_id: 117, role_id: ROLE_AUTHOR },
    { work_id: 1029, person_id: 119, role_id: ROLE_AUTHOR },
    { work_id: 1030, person_id: 119, role_id: ROLE_AUTHOR },

    # Edge case works
    # 2001: person_id=0 (著者なし) — cards.rs でスキップされるケース
    { work_id: 2001, person_id: 0, role_id: ROLE_AUTHOR },
    # 2002: HTML特殊文字を含む作品
    { work_id: 2002, person_id: 202, role_id: ROLE_AUTHOR },
    # 2003: 空フィールド作品（人物201は作品を持つが、他の作品は持たない）
    { work_id: 2003, person_id: 201, role_id: ROLE_AUTHOR }
  ].freeze

  # News entries (10 entries covering year boundaries and flags)
  NEWS_ENTRIES = [
    { id: 101, title: '今日のトピックス', body: "今日のお知らせ本文です。\n\n詳細はこちら。",
      flag: true, published_on: Time.zone.today },
    { id: 102, title: '今日の普通ニュース', body: "普通のお知らせ本文です。\n\n詳細はこちら。",
      flag: false, published_on: Time.zone.today },
    { id: 103, title: '昨年のトピックス', body: "去年のお知らせ本文です。\n\n詳細はこちら。",
      flag: true, published_on: Time.zone.today - 365 },
    { id: 104, title: '昨年の普通ニュース', body: "去年の普通のお知らせ本文です。\n\n詳細はこちら。",
      flag: false, published_on: Time.zone.today - 365 },
    { id: 105, title: '古いお知らせ1997', body: "1997年のお知らせ本文です。\n\n詳細はこちら。",
      flag: false, published_on: Date.new(1997, 8, 1) },
    { id: 106, title: '2000年のお知らせ', body: "2000年のお知らせ本文です。\n\n詳細はこちら。",
      flag: true, published_on: Date.new(2000, 1, 1) },
    { id: 107, title: '2001年のお知らせ', body: "2001年のお知らせ本文です。\n\n詳細はこちら。",
      flag: false, published_on: Date.new(2001, 3, 15) },
    { id: 108, title: '2010年のお知らせ', body: "2010年のお知らせ本文です。\n\n詳細はこちら。",
      flag: true, published_on: Date.new(2010, 6, 1) },
    { id: 109, title: '2020年のお知らせ', body: "2020年のお知らせ本文です。\n\n詳細はこちら。",
      flag: false, published_on: Date.new(2020, 4, 1) },
    { id: 110, title: '2025年のお知らせ', body: "2025年のお知らせ本文です。\n\n詳細はこちら。",
      flag: true, published_on: Date.new(2025, 12, 1) },
    # 201: bodyが空のニュース
    { id: 201, title: '空の本文', body: '', flag: false, published_on: Time.zone.today }
  ].freeze

  # Sites (5 sites)
  SITES = [
    { id: 101, name: '青空文庫関連サイト1', url: 'https://example.com/aozora1' },
    { id: 102, name: '青空文庫関連サイト2', url: 'https://example.com/aozora2' },
    { id: 103, name: '作家関連サイト', url: 'https://example.com/author' },
    { id: 104, name: '翻訳関連サイト', url: 'https://example.com/translation' },
    { id: 105, name: '研究サイト', url: 'https://example.com/research' }
  ].freeze

  # WorkSites (3 relationships)
  WORK_SITES = [
    { work_id: 1012, site_id: 101 },
    { work_id: 1012, site_id: 102 },
    { work_id: 1013, site_id: 103 }
  ].freeze

  # PersonSites (2 relationships)
  PERSON_SITES = [
    { person_id: 109, site_id: 104 },
    { person_id: 110, site_id: 105 }
  ].freeze

  # BasePeople (3 aliases)
  BASE_PEOPLE = [
    { person_id: 110, original_person_id: 101 },
    { person_id: 111, original_person_id: 102 },
    { person_id: 112, original_person_id: 103 }
  ].freeze

  # OriginalBooks (10 books)
  ORIGINAL_BOOKS = [
    { work_id: 1001, title: '雪の早晨底本', publisher: '春出版社',
      first_pubdate: '1910年', input_edition: '2000年入力版',
      proof_edition: '2001年校正版', booktype_id: BOOKTYPE_ID },
    { work_id: 1002, title: '春の夢底本', publisher: '夏出版社',
      first_pubdate: '1920年', input_edition: '2010年入力版',
      proof_edition: '2011年校正版', booktype_id: BOOKTYPE_ID },
    { work_id: 1006, title: '星の歌底本', publisher: '秋出版社',
      first_pubdate: '1930年', input_edition: '2020年入力版',
      proof_edition: '2021年校正版', booktype_id: BOOKTYPE_ID },
    { work_id: 1007, title: '月の光底本', publisher: '冬出版社',
      first_pubdate: '1940年', input_edition: '1990年入力版',
      proof_edition: '1991年校正版', booktype_id: BOOKTYPE_ID },
    { work_id: 1010, title: '共同作品底本', publisher: '青出版社',
      first_pubdate: '1950年', input_edition: '2005年入力版',
      proof_edition: '2006年校正版', booktype_id: BOOKTYPE_ID },
    { work_id: 1011, title: '翻訳作品底本', publisher: '赤出版社',
      first_pubdate: '1960年', input_edition: '2015年入力版',
      proof_edition: '2016年校正版', booktype_id: BOOKTYPE_ID },
    { work_id: 1013, title: '著作権あり底本', publisher: '緑出版社',
      first_pubdate: '1970年', input_edition: '2018年入力版',
      proof_edition: '2019年校正版', booktype_id: BOOKTYPE_ID },
    { work_id: 1016, title: 'か行作品底本', publisher: '黄出版社',
      first_pubdate: '1980年', input_edition: '2008年入力版',
      proof_edition: '2009年校正版', booktype_id: BOOKTYPE_ID },
    { work_id: 1026, title: '昨年作品底本', publisher: '紫出版社',
      first_pubdate: '1990年', input_edition: '2024年入力版',
      proof_edition: '2025年校正版', booktype_id: BOOKTYPE_ID },
    { work_id: 1027, title: '今年作品底本', publisher: '橙出版社',
      first_pubdate: '2000年', input_edition: '2025年入力版',
      proof_edition: '2026年校正版', booktype_id: BOOKTYPE_ID }
  ].freeze

  # Bibclasses (10 bibclasses)
  BIBCLASSES = [
    { work_id: 1001, name: 'NDC', num: '913' },
    { work_id: 1002, name: 'NDC', num: '914' },
    { work_id: 1003, name: 'NDC', num: '911' },
    { work_id: 1006, name: 'NDC', num: '121' },
    { work_id: 1007, name: 'NDC', num: '289' },
    { work_id: 1010, name: 'NDC', num: '596' },
    { work_id: 1011, name: 'NDC', num: 'K913' },
    { work_id: 1013, name: 'NDC', num: '913' },
    { work_id: 1016, name: 'NDC', num: '914' },
    { work_id: 1027, name: 'NDC', num: '911' }
  ].freeze

  # Workers (5 workers)
  WORKERS = [
    { id: 101, name: '入力者A', name_kana: 'にゅうりょくしゃえー', sortkey: 'にゅうりょくしゃえー' },
    { id: 102, name: '校正者B', name_kana: 'こうせいしゃびー', sortkey: 'こうせいしゃびー' },
    { id: 103, name: '入力者C', name_kana: 'にゅうりょくしゃしー', sortkey: 'にゅうりょくしゃしー' },
    { id: 104, name: '校正者D', name_kana: 'こうせいしゃでぃー', sortkey: 'こうせいしゃでぃー' },
    { id: 105, name: '入力者E', name_kana: 'にゅうりょくしゃいー', sortkey: 'にゅうりょくしゃいー' }
  ].freeze

  # WorkerSecrets (5 worker secrets)
  WORKER_SECRETS = [
    { worker_id: 101, email: 'worker-a@example.com', url: 'https://example.com/worker-a', note: '入力者Aのメモ' },
    { worker_id: 102, email: 'worker-b@example.com', url: 'https://example.com/worker-b', note: '校正者Bのメモ' },
    { worker_id: 103, email: 'worker-c@example.com', url: 'https://example.com/worker-c', note: '入力者Cのメモ' },
    { worker_id: 104, email: 'worker-d@example.com', url: 'https://example.com/worker-d', note: '校正者Dのメモ' },
    { worker_id: 105, email: 'worker-e@example.com', url: 'https://example.com/worker-e', note: '入力者Eのメモ' }
  ].freeze

  # WorkWorkers (15 work-worker relationships)
  WORK_WORKERS = [
    { work_id: 1001, worker_id: 101, worker_role_id: WORKER_ROLE_INPUT },
    { work_id: 1001, worker_id: 102, worker_role_id: WORKER_ROLE_PROOFREAD },
    { work_id: 1002, worker_id: 103, worker_role_id: WORKER_ROLE_INPUT },
    { work_id: 1003, worker_id: 104, worker_role_id: WORKER_ROLE_INPUT },
    { work_id: 1003, worker_id: 105, worker_role_id: WORKER_ROLE_PROOFREAD },
    { work_id: 1006, worker_id: 101, worker_role_id: WORKER_ROLE_INPUT },
    { work_id: 1007, worker_id: 102, worker_role_id: WORKER_ROLE_INPUT },
    { work_id: 1007, worker_id: 103, worker_role_id: WORKER_ROLE_PROOFREAD },
    { work_id: 1010, worker_id: 104, worker_role_id: WORKER_ROLE_INPUT },
    { work_id: 1011, worker_id: 105, worker_role_id: WORKER_ROLE_INPUT },
    { work_id: 1011, worker_id: 101, worker_role_id: WORKER_ROLE_PROOFREAD },
    { work_id: 1013, worker_id: 102, worker_role_id: WORKER_ROLE_INPUT },
    { work_id: 1013, worker_id: 103, worker_role_id: WORKER_ROLE_PROOFREAD },
    { work_id: 1016, worker_id: 104, worker_role_id: WORKER_ROLE_INPUT },
    { work_id: 1027, worker_id: 105, worker_role_id: WORKER_ROLE_INPUT }
  ].freeze

  # Workfiles (10 workfiles)
  WORKFILES = [
    { work_id: 1001, filetype_id: FILETYPE_ID, compresstype_id: COMPRESSTYPE_ID,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 10240, filename: '1001.txt', revision_count: 1,
      registrated_on: '2020-01-01', last_updated_on: '2020-01-01' },
    { work_id: 1002, filetype_id: FILETYPE_ID, compresstype_id: 2,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 20480, filename: '1002.zip', revision_count: 2,
      registrated_on: '2020-02-01', last_updated_on: '2020-02-15' },
    { work_id: 1003, filetype_id: 3, compresstype_id: COMPRESSTYPE_ID,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 15360, filename: '1003.html', revision_count: 1,
      registrated_on: '2020-03-01', last_updated_on: '2020-03-01' },
    { work_id: 1006, filetype_id: FILETYPE_ID, compresstype_id: COMPRESSTYPE_ID,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 30720, filename: '1006.txt', revision_count: 3,
      registrated_on: '2020-06-01', last_updated_on: '2020-07-01' },
    { work_id: 1007, filetype_id: 1, compresstype_id: 2,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 25600, filename: '1007.zip', revision_count: 2,
      registrated_on: '2020-07-01', last_updated_on: '2020-08-01' },
    { work_id: 1010, filetype_id: FILETYPE_ID, compresstype_id: COMPRESSTYPE_ID,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 40960, filename: '1010.txt', revision_count: 1,
      registrated_on: '2020-10-01', last_updated_on: '2020-10-01' },
    { work_id: 1011, filetype_id: 3, compresstype_id: COMPRESSTYPE_ID,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 51200, filename: '1011.html', revision_count: 4,
      registrated_on: '2020-11-01', last_updated_on: '2020-12-01' },
    { work_id: 1013, filetype_id: FILETYPE_ID, compresstype_id: 2,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 20480, filename: '1013.zip', revision_count: 2,
      registrated_on: '2021-01-01', last_updated_on: '2021-02-01' },
    { work_id: 1016, filetype_id: FILETYPE_ID, compresstype_id: COMPRESSTYPE_ID,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 15360, filename: '1016.txt', revision_count: 1,
      registrated_on: '2021-04-01', last_updated_on: '2021-04-01' },
    { work_id: 1027, filetype_id: 3, compresstype_id: COMPRESSTYPE_ID,
      file_encoding_id: FILE_ENCODING_ID, charset_id: CHARSET_ID,
      filesize: 10240, filename: '1027.html', revision_count: 1,
      registrated_on: '2026-01-01', last_updated_on: '2026-01-01' }
  ].freeze
end

# Load fixture data

# rubocop:disable Rails/Output

puts 'Loading parity fixture data...'

# Insert in dependency order
Person.insert_all(ParityFixture::PERSONS.map { |p| p.merge(created_at: Time.current, updated_at: Time.current) })
puts "  Persons: #{ParityFixture::PERSONS.size}"

Work.insert_all(ParityFixture::WORKS.map { |w| w.merge(created_at: Time.current, updated_at: Time.current) })
puts "  Works: #{ParityFixture::WORKS.size}"

WorkPerson.insert_all(ParityFixture::WORK_PEOPLE.map { |wp| wp.merge(created_at: Time.current, updated_at: Time.current) })
puts "  WorkPeople: #{ParityFixture::WORK_PEOPLE.size}"

NewsEntry.insert_all(ParityFixture::NEWS_ENTRIES.map { |n| n.merge(created_at: Time.current, updated_at: Time.current) })
puts "  NewsEntries: #{ParityFixture::NEWS_ENTRIES.size}"

Site.insert_all(ParityFixture::SITES.map { |s| s.merge(created_at: Time.current, updated_at: Time.current) })
puts "  Sites: #{ParityFixture::SITES.size}"

WorkSite.insert_all(ParityFixture::WORK_SITES.map { |ws| ws.merge(created_at: Time.current, updated_at: Time.current) })
puts "  WorkSites: #{ParityFixture::WORK_SITES.size}"

PersonSite.insert_all(ParityFixture::PERSON_SITES.map { |ps| ps.merge(created_at: Time.current, updated_at: Time.current) })
puts "  PersonSites: #{ParityFixture::PERSON_SITES.size}"

BasePerson.insert_all(ParityFixture::BASE_PEOPLE.map { |bp| bp.merge(created_at: Time.current, updated_at: Time.current) })
puts "  BasePeople: #{ParityFixture::BASE_PEOPLE.size}"

OriginalBook.insert_all(ParityFixture::ORIGINAL_BOOKS.map { |ob| ob.merge(created_at: Time.current, updated_at: Time.current) })
puts "  OriginalBooks: #{ParityFixture::ORIGINAL_BOOKS.size}"

Bibclass.insert_all(ParityFixture::BIBCLASSES.map { |b| b.merge(created_at: Time.current, updated_at: Time.current) })
puts "  Bibclasses: #{ParityFixture::BIBCLASSES.size}"

Worker.insert_all(ParityFixture::WORKERS.map { |w| w.merge(created_at: Time.current, updated_at: Time.current) })
puts "  Workers: #{ParityFixture::WORKERS.size}"

WorkerSecret.insert_all(ParityFixture::WORKER_SECRETS.map { |ws| ws.merge(created_at: Time.current, updated_at: Time.current) })
puts "  WorkerSecrets: #{ParityFixture::WORKER_SECRETS.size}"

WorkWorker.insert_all(ParityFixture::WORK_WORKERS.map { |ww| ww.merge(created_at: Time.current, updated_at: Time.current) })
puts "  WorkWorkers: #{ParityFixture::WORK_WORKERS.size}"

Workfile.insert_all(ParityFixture::WORKFILES.map { |wf| wf.merge(created_at: Time.current, updated_at: Time.current) })
puts "  Workfiles: #{ParityFixture::WORKFILES.size}"

puts 'Parity fixture loaded successfully.'
# rubocop:enable Rails/Output
