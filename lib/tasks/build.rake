# frozen_string_literal: true

require 'fileutils'

class StaticPageBuilder
  def initialize(target_dir: nil)
    @target_dir = target_dir || Rails.root.join('build')
  end

  def copy_precompiled_assets
    Rake::Task["assets:precompile"].invoke
    FileUtils.mkdir_p(@target_dir.join('assets'))
    FileUtils.cp_r(Rails.root.join('public/assets'), @target_dir)
  end

  def copy_public_images
    FileUtils.mkdir_p(@target_dir.join('images'))
    FileUtils.cp_r(Rails.root.join('public/images'), @target_dir)
  end

  def force_clean
    FileUtils.remove_entry_secure(@target_dir, :force)
  end

  def build_html(component, path:)
    html = ApplicationController.renderer.render(component, layout: nil)
    rel_path = path.sub(%r(^/), '')
    full_path = @target_dir.join(rel_path)
    puts "Generate #{full_path}"
    write_with_mkdir(full_path, html)
  end

  private

  def write_with_mkdir(full_path, html)
    dir = File.dirname(full_path)
    FileUtils.mkdir_p(dir)
    File.write(full_path, html)
  end
end

namespace :build do
  desc 'Generate all pages'
  task all: :environment do
    start_time = Time.current

    url = Rails.application.routes.url_helpers
    builder = StaticPageBuilder.new

    builder.force_clean

    builder.copy_precompiled_assets
    builder.copy_public_images

    builder.build_html(::Pages::Top::IndexPageComponent.new,
                       path: 'index.html')

    builder.build_html(::Pages::IndexPages::IndexTopPageComponent.new,
                       path: 'index_pages/index_top.html')

    builder.build_html(::Pages::IndexPages::IndexAllPageComponent.new,
                       path: 'index_pages/index_all.html')

    builder.build_html(::Pages::IndexPages::PersonAllPageComponent.new,
                       path: 'index_pages/person_all.html')

    current_year = Time.zone.now.year
    builder.build_html(::Pages::NewsEntries::IndexPageComponent.new(year: current_year),
                       path: 'soramoyou/soramoyouindex.html')

    begin_year = Pages::NewsEntries::IndexYearPageComponent::BEGIN_YEAR
    (begin_year..current_year).each do |year|
      builder.build_html(::Pages::NewsEntries::IndexYearPageComponent.new(year: year),
                       path: "soramoyou/soramoyou#{year}.html")
    end

    date = WhatsnewsController::LIMIT_DATE
    item_count = WhatsnewsController::ITEM_COUNT

    works = Work.order(started_on: :desc).where('started_on >= ?', date)
    total_page = works.count.fdiv(item_count).floor # 割り切れない場合は切り上げ
    (1..total_page).each do |page|
      pagy = Pagy.new(count: works.count, page: page, items: item_count)
      current_works = works.offset(pagy.offset).limit(pagy.items)
      path = url.whatsnew_index_pages_path(page: page, format: :html)
      builder.build_html(::Pages::Whatsnew::IndexPageComponent.new(date: date,
                                                                   pagy: pagy,
                                                                   works: current_works),
                         path: path)
    end

    (::Pages::Whatsnew::IndexPageComponent::FIRST_YEAR..2020).each do |year|
      works = Work.with_year_and_status(year, 1).where('started_on >= ? AND started_on < ?', "#{year}-01-01", "#{year+1}-01-01").order(started_on: :desc)
      total_page = works.count.fdiv(item_count).floor # 割り切れない場合は切り上げ
      (1..total_page).each do |page|
        pagy = Pagy.new(count: works.count, page: page, items: item_count)
        current_works = works.offset(pagy.offset).limit(pagy.items)
        path = url.whatsnew_year_index_pages_path(year_page: "#{year}_#{page}", format: :html)
        builder.build_html(::Pages::Whatsnew::IndexYearPageComponent.new(year: year,
                                                                         pagy: pagy,
                                                                         works: current_works),
                           path: path)
      end
    end

    KanaUtils::ROMA2KANA_CHARS.keys.each do |key|
      builder.build_html(::Pages::People::IndexPageComponent.new(id: key),
                         path: "index_pages/person_#{key}.html")
      builder.build_html(::Pages::IndexPages::PersonAllIndexPageComponent.new(id: key),
                         path: "index_pages/person_all_#{key}.html")
    end

    Person.all.find_each do |person|
      builder.build_html(Pages::People::ShowPageComponent.new(person: person),
                         path: "index_pages/person#{person.id}.html")
      person.works.all.pluck(:id).each do |card_id|
        builder.build_html(Pages::Cards::ShowPageComponent.new(person_id: person.id,
                                                               card_id: card_id),
                           path: url.card_path(person_id: format('%06d', person.id),
                                               card_id: card_id,
                                               format: :html))
      end
    end

    puts "Done: #{Time.current - start_time}"
  end
end
