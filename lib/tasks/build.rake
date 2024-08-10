# frozen_string_literal: true

require 'fileutils'

namespace :build do
  desc 'Clean build dir'
  task clean: :environment do
    builder = StaticPageBuilder.new

    builder.force_clean
  end

  desc 'Prepare asset files'
  task prepare_assets: :environment do
    builder = StaticPageBuilder.new

    builder.copy_precompiled_assets
    builder.copy_public_images
  end

  desc 'Copy zip files'
  task copy_zip_files: :environment do
    builder = StaticPageBuilder.new

    builder.copy_zip_files
  end

  desc 'rsync'
  task rsync: :environment do
    builder = StaticPageBuilder.new
    builder.create_rsync_keyfile(ENV.fetch('RSYNC_PASS_FILE', '').gsub('\n', "\n"))
    server_path = ENV.fetch('RSYNC_SERVER_PATH', nil)
    src_dir = "#{builder.target_dir}/"
    cmd = "rsync -avhz -e \"ssh -o StrictHostKeyChecking=no -i #{builder.rsync_keyfile}\" #{src_dir} #{server_path}"
    puts cmd
    system(cmd)
  end

  desc 'build index pages'
  task generate_indexes: :environment do
    builder = StaticPageBuilder.new

    builder.build_html(Pages::Top::IndexPageComponent.new,
                       path: 'index.html')

    builder.build_html(Pages::IndexPages::IndexTopPageComponent.new,
                       path: 'index_pages/index_top.html')

    builder.build_html(Pages::IndexPages::IndexAllPageComponent.new,
                       path: 'index_pages/index_all.html')

    builder.build_html(Pages::IndexPages::PersonAllPageComponent.new,
                       path: 'index_pages/person_all.html')
  end

  desc 'build works index pages'
  task generate_work_indexes: :environment do
    builder = StaticPageBuilder.new

    Kana.each_sym_and_char do |id, kana|
      item_count = 50

      works = Work.published.with_title_firstchar(kana).order(:sortkey, :id).all

      total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
      (1..total_page).each do |page|
        pagy = Pagy.new(count: works.count, items: item_count, page: page)
        current_works = works.offset(pagy.offset).limit(pagy.items)

        builder.build_html(Pages::IndexPages::WorkIndexPageComponent.new(id: id,
                                                                         kana: kana,
                                                                         pagy: pagy,
                                                                         works: current_works),
                           path: "index_pages/sakuhin_#{id}#{page}.html")
      end
    end
  end

  desc 'build WIP works index pages'
  task generate_wip_work_indexes: :environment do
    builder = StaticPageBuilder.new

    Kana.each_sym_and_char do |id, kana| # rubocop:disable Style/CombinableLoops
      item_count = 50

      works = Work.unpublished.with_title_firstchar(kana).order(:sortkey, :id).all

      total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
      (1..total_page).each do |page|
        pagy = Pagy.new(count: works.count, items: item_count, page: page)
        current_works = works.offset(pagy.offset).limit(pagy.items)

        builder.build_html(Pages::IndexPages::WorkInpIndexPageComponent.new(id: id,
                                                                            kana: kana,
                                                                            pagy: pagy,
                                                                            works: current_works),
                           path: "index_pages/sakuhin_inp_#{id}#{page}.html")
      end
    end
  end

  desc 'build soramoyou pages'
  task generate_soramoyou: :environment do
    builder = StaticPageBuilder.new

    current_year = Time.zone.now.year
    builder.build_html(Pages::NewsEntries::IndexPageComponent.new(year: current_year),
                       path: 'soramoyou/soramoyouindex.html')

    begin_year = Pages::NewsEntries::IndexYearPageComponent::BEGIN_YEAR
    (begin_year..current_year).each do |year|
      builder.build_html(Pages::NewsEntries::IndexYearPageComponent.new(year: year),
                         path: "soramoyou/soramoyou#{year}.html")
    end
  end

  desc 'build whatsnew pages'
  task generate_whatsnew: :environment do
    url = Rails.application.routes.url_helpers
    builder = StaticPageBuilder.new

    item_count = WhatsnewsController::ITEM_COUNT
    date = Time.zone.today

    works = Work.latest_published(until_date: date).order(started_on: :desc, id: :asc)
    total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
    (1..total_page).each do |page|
      pagy = Pagy.new(count: works.count, page: page, items: item_count)
      current_works = works.offset(pagy.offset).limit(pagy.items)
      path = url.whatsnew_index_pages_path(page: page, format: :html)
      builder.build_html(Pages::Whatsnew::IndexPageComponent.new(date: date,
                                                                 pagy: pagy,
                                                                 works: current_works),
                         path: path)
    end

    prev_year = date.year - 1
    (Pages::Whatsnew::IndexPageComponent::FIRST_YEAR..prev_year).each do |year|
      works = Work.latest_published(year: year).order(started_on: :desc, id: :asc)
      total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
      (1..total_page).each do |page|
        pagy = Pagy.new(count: works.count, page: page, items: item_count)
        current_works = works.offset(pagy.offset).limit(pagy.items)
        path = url.whatsnew_year_index_pages_path(year_page: "#{year}_#{page}", format: :html)
        builder.build_html(Pages::Whatsnew::IndexYearPageComponent.new(year: year,
                                                                       date: date,
                                                                       pagy: pagy,
                                                                       works: current_works),
                           path: path)
      end
    end
  end

  desc 'build person index pages'
  task generate_person_index: :environment do
    builder = StaticPageBuilder.new

    Kana.each_column_key do |key|
      builder.build_html(Pages::People::IndexPageComponent.new(id: key),
                         path: "index_pages/person_#{key}.html")

      builder.build_html(Pages::IndexPages::PersonAllIndexPageComponent.new(id: key),
                         path: "index_pages/person_all_#{key}.html")

      builder.build_html(Pages::IndexPages::PersonInpIndexPageComponent.new(id: key),
                         path: "index_pages/person_inp_#{key}.html")
    end
  end

  desc 'build person pages'
  task generate_person: :environment do
    builder = StaticPageBuilder.new

    Person.find_each do |person|
      builder.build_html(Pages::People::ShowPageComponent.new(person: person),
                         path: "index_pages/person#{person.id}.html")
    end
  end

  desc 'build work pages'
  task generate_work: :environment do
    url = Rails.application.routes.url_helpers
    builder = StaticPageBuilder.new

    Person.find_each do |person|
      person.works.published.pluck(:id).each do |card_id|
        builder.build_html(Pages::Cards::ShowPageComponent.new(person_id: person.id,
                                                               card_id: card_id),
                           path: url.card_path(person_id: format('%06d', person.id),
                                               card_id: card_id,
                                               format: :html))
      end
    end
  end

  desc 'build WIP person index pages'
  task generate_wip_person_index: :environment do
    url = Rails.application.routes.url_helpers
    builder = StaticPageBuilder.new

    Person.find_each do |person|
      item_count = 20
      works = person.works.unpublished
      total_page = works.count.fdiv(item_count).ceil
      (1..total_page).each do |page|
        pagy = Pagy.new(count: works.count, items: item_count, page: page)
        current_works = works.offset(pagy.offset).limit(pagy.items)
        builder.build_html(Pages::IndexPages::ListInpShowPageComponent.new(author: person,
                                                                           pagy: pagy,
                                                                           works: current_works),
                           path: "index_pages/list_inp#{person.id}_#{page}.html")
      end
    end
  end

  desc 'Build all HTML files'
  task generate: %i[build:generate_indexes build:generate_work_indexes build:generate_wip_work_indexes build:generate_soramoyou build:generate_whatsnew build:generate_person_index build:generate_person build:generate_work build:generate_wip_person_index]

  desc 'Generate all pages'
  task all: %i[environment build:clean build:prepare_assets build:copy_zip_files] do
    start_time = Time.current

    Rake::Task['build:generate'].invoke

    puts "Done: #{Time.current - start_time}"
  end

  desc 'exec `all` and `rsync`'
  task all_and_rsync: %i[build:all build:rsync]
end
