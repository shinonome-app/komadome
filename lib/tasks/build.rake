# frozen_string_literal: true

require 'fileutils'

namespace :build do
  desc 'Clean build dir'
  task clean: :environment do
    StaticPageBuilder.new do |builder|
      builder.force_clean
    end
  end

  desc 'Prepare asset files'
  task prepare_assets: :environment do
    StaticPageBuilder.new do |builder|
      builder.copy_precompiled_assets
      builder.copy_public_images
    end
  end

  desc 'Copy zip files'
  task copy_zip_files: :environment do
    StaticPageBuilder.new do |builder|
      builder.copy_zip_files
    end
  end

  desc 'rsync'
  task rsync: :environment do
    StaticPageBuilder.new do |builder|
      builder.create_rsync_keyfile(ENV.fetch('RSYNC_PASS_FILE', ''))
      server_path = ENV.fetch('RSYNC_SERVER_PATH', nil)
      src_dir = "#{builder.target_dir}/"
      cmd = "rsync -avhz -e \"ssh -o StrictHostKeyChecking=no -i #{builder.rsync_keyfile}\" #{src_dir} #{server_path}"
      puts cmd
      system(cmd)
    end
  end

  desc 'build index pages'
  task generate_indexes: :environment do
    StaticPageBuilder.new do |builder|
      builder.build_html(
        paths:
          [
            'index.html',
            'index_pages/index_top.html',
            'index_pages/index_all.html',
            'index_pages/person_all.html'
          ]
      )
    end
  end

  desc 'build works index pages'
  task generate_work_indexes: :environment do
    StaticPageBuilder.new do |builder|
      Kana.each_sym_and_char do |id, kana|
        item_count = 50

        works = Work.published.with_title_firstchar(kana).order(:sortkey, :id).all

        total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
        (1..total_page).each do |page|
          builder.build_html(paths: ["index_pages/sakuhin_#{id}#{page}.html"])
        end
      end
    end
  end

  desc 'build WIP works index pages'
  task generate_wip_work_indexes: :environment do
    StaticPageBuilder.new do |builder|
      Kana.each_sym_and_char do |id, kana|
        item_count = 50

        works = Work.unpublished.with_title_firstchar(kana).order(:sortkey, :id).all

        total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
        (1..total_page).each do |page|
          builder.build_html(paths: ["index_pages/sakuhin_inp_#{id}#{page}.html"])
        end
      end
    end
  end

  desc 'build soramoyou pages'
  task generate_soramoyou: :environment do
    StaticPageBuilder.new do |builder|
      current_year = Time.zone.now.year
      builder.build_html(paths: ['soramoyou/soramoyouindex.html'])

      begin_year = Pages::NewsEntries::IndexYearPageComponent::BEGIN_YEAR
      (begin_year..current_year).each do |year|
        builder.build_html(paths: ["soramoyou/soramoyou#{year}.html"])
      end
    end
  end

  desc 'build whatsnew pages'
  task generate_whatsnew: :environment do
    StaticPageBuilder.new do |builder|
      url = Rails.application.routes.url_helpers

      item_count = WhatsnewsController::ITEM_COUNT
      date = Time.zone.today

      works = Work.latest_published(until_date: date).order(started_on: :desc, id: :asc)
      total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
      (1..total_page).each do |page|
        path = url.whatsnew_index_pages_path(page:, format: :html)
        builder.build_html(paths: [path])
      end

      prev_year = date.year - 1
      (Pages::Whatsnew::IndexPageComponent::FIRST_YEAR..prev_year).each do |year|
        works = Work.latest_published(year: year).order(started_on: :desc, id: :asc)
        total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
        (1..total_page).each do |page|
          path = url.whatsnew_year_index_pages_path(year_page: "#{year}_#{page}", format: :html)
          builder.build_html(paths: [path])
        end
      end
    end
  end

  desc 'build person index pages'
  task generate_person_index: :environment do
    StaticPageBuilder.new do |builder|
      Kana.each_column_key do |key|
        builder.build_html(
          paths:
            [
              "index_pages/person_#{key}.html",
              "index_pages/person_all_#{key}.html",
              "index_pages/person_inp_#{key}.html"
            ]
        )
      end
    end
  end

  desc 'build person pages'
  task generate_person: :environment do
    StaticPageBuilder.new do |builder|
      Person.find_each do |person|
        builder.build_html(paths: ["index_pages/person#{person.id}.html"])
      end
    end
  end

  desc 'build work pages'
  task generate_work: :environment do
    StaticPageBuilder.new do |builder|
      url = Rails.application.routes.url_helpers

      Person.find_each do |person|
        person.works.published.pluck(:id).each do |card_id|
          builder.build_html(
            paths: [
              url.card_path(
                person_id: format('%06d', person.id),
                card_id: card_id,
                format: :html
              )
            ]
          )
        end
      end
    end
  end

  desc 'build WIP person index pages'
  task generate_wip_person_index: :environment do
    StaticPageBuilder.new do |builder|
      Person.find_each do |person|
        item_count = 50
        works = person.works.unpublished.order(:sortkey, :id)
        total_page = works.count.fdiv(item_count).ceil
        (1..total_page).each do |page|
          builder.build_html(paths: ["index_pages/list_inp#{person.id}_#{page}.html"])
        end
      end
    end
  end

  desc 'Build all HTML files'
  task generate: %i[
    build:generate_indexes
    build:generate_work_indexes
    build:generate_wip_work_indexes
    build:generate_soramoyou
    build:generate_whatsnew
    build:generate_person_index
    build:generate_person
    build:generate_work
    build:generate_wip_person_index
  ]

  desc 'Generate all pages'
  task all: %i[environment build:clean build:prepare_assets build:copy_zip_files] do
    start_time = Time.current

    Rake::Task['build:generate'].invoke

    puts "Done: #{Time.current - start_time}"
  end

  desc 'exec `all` and `rsync`'
  task all_and_rsync: %i[build:all build:rsync]
end
