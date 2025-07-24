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

        # Use count instead of loading all records
        work_count = Work.published.with_title_firstchar(kana).count

        total_page = work_count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
        paths = (1..total_page).map { |page| "index_pages/sakuhin_#{id}#{page}.html" }
        builder.build_html(paths: paths)
      end
    end
  end

  desc 'build WIP works index pages'
  task generate_wip_work_indexes: :environment do
    StaticPageBuilder.new do |builder|
      Kana.each_sym_and_char do |id, kana|
        item_count = 50

        # Use count instead of loading all records
        work_count = Work.unpublished.with_title_firstchar(kana).count

        total_page = work_count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
        paths = (1..total_page).map { |page| "index_pages/sakuhin_inp_#{id}#{page}.html" }
        builder.build_html(paths: paths)
      end
    end
  end

  desc 'build soramoyou pages'
  task generate_soramoyou: :environment do
    StaticPageBuilder.new do |builder|
      current_year = Time.zone.now.year
      builder.build_html(paths: ['soramoyou/soramoyouindex.html'])

      begin_year = Pages::NewsEntries::IndexYearPageComponent::BEGIN_YEAR
      paths = (begin_year..current_year).map { |year| "soramoyou/soramoyou#{year}.html" }
      builder.build_html(paths: paths)
    end
  end

  desc 'build whatsnew pages'
  task generate_whatsnew: :environment do
    StaticPageBuilder.new do |builder|
      url = Rails.application.routes.url_helpers

      item_count = WhatsnewsController::ITEM_COUNT
      date = Time.zone.today

      # Use count directly instead of loading records
      work_count = Work.latest_published(until_date: date).count
      total_page = work_count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
      paths = (1..total_page).map { |page| url.whatsnew_index_pages_path(page:, format: :html) }
      builder.build_html(paths: paths)

      prev_year = date.year - 1
      # Pre-calculate counts for all years to reduce queries
      year_counts = {}
      (Pages::Whatsnew::IndexPageComponent::FIRST_YEAR..prev_year).each do |year|
        year_counts[year] = Work.latest_published(year: year).count
      end

      paths = []
      year_counts.each do |year, count|
        total_page = count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
        (1..total_page).each do |page|
          paths << url.whatsnew_year_index_pages_path(year_page: "#{year}_#{page}", format: :html)
        end
      end
      builder.build_html(paths: paths)
    end
  end

  desc 'build person index pages'
  task generate_person_index: :environment do
    StaticPageBuilder.new do |builder|
      paths = []
      Kana.each_column_key do |key|
        paths.push(
          "index_pages/person_#{key}.html",
          "index_pages/person_all_#{key}.html",
          "index_pages/person_inp_#{key}.html"
        )
      end
      builder.build_html(paths: paths)
    end
  end

  desc 'build person pages'
  task generate_person: :environment do
    StaticPageBuilder.new do |builder|
      # Eager load associations to prevent N+1 queries
      Person.includes(:works, :work_people, :sites, :person_sites).find_each do |person|
        builder.build_html(paths: ["index_pages/person#{person.id}.html"])
      end
    end
  end

  desc 'build work pages'
  task generate_work: :environment do
    StaticPageBuilder.new do |builder|
      url = Rails.application.routes.url_helpers

      # Eager load works and related associations to prevent N+1 queries
      # Also batch the work building by loading all published works with their associations
      Person.includes(works: [:work_people, :people, :sites, :workfiles, :work_status]).find_each do |person|
        person.works.published.each do |work|
          builder.build_html(
            paths: [
              url.card_path(
                person_id: format('%06d', person.id),
                card_id: work.id,
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
      # Eager load works to prevent N+1 queries
      Person.includes(:works).find_each do |person|
        item_count = 50
        # Use count instead of loading all records
        work_count = person.works.unpublished.count
        total_page = work_count.fdiv(item_count).ceil
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
    # ログレベルを一時的に変更
    original_log_level = Rails.logger.level
    Rails.logger.level = ENV.fetch('RAILS_LOG_LEVEL', 'warn').to_sym

    # ActiveRecordのログも抑制
    if defined?(ActiveRecord::Base)
      original_ar_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = Rails.logger
    end

    start_time = Time.current

    begin
      Rake::Task['build:generate'].invoke

      puts "Done: #{Time.current - start_time}"
    ensure
      # ログレベルを元に戻す
      Rails.logger.level = original_log_level
      ActiveRecord::Base.logger = original_ar_logger if defined?(ActiveRecord::Base) && original_ar_logger
    end
  end

  desc 'exec `all` and `rsync`'
  task all_and_rsync: %i[build:all build:rsync]
end
