# frozen_string_literal: true

require 'fileutils'

# Static page builder
class StaticPageBuilder
  attr_reader :target_dir, :rsync_keyfile

  def initialize(target_dir: nil)
    @target_dir = target_dir || Pathname.new('/tmp/build')
    @rsync_keyfile = '/tmp/rsync.key'
  end

  def copy_precompiled_assets
    Rake::Task['assets:precompile'].invoke
    FileUtils.mkdir_p(@target_dir.join('assets'))
    Rails.public_path.join('assets').children.each do |file|
      FileUtils.mv(Rails.public_path.join('assets', file), @target_dir.join('assets'))
    end
  end

  def copy_public_images
    FileUtils.mkdir_p(@target_dir.join('images'))
    FileUtils.cp_r(Rails.public_path.join('images'), @target_dir)
  end

  def copy_zip_files
    FileUtils.mkdir_p(@target_dir.join('index_pages'))
    Rails.root.glob('data/csv_zip/*.zip') do |file|
      FileUtils.cp(file, @target_dir.join('index_pages'))
    end
  end

  def force_clean
    FileUtils.remove_entry_secure(@target_dir, :force)
  end

  def build_html(component, path:)
    html = ApplicationController.renderer.render(component, layout: nil)
    rel_path = path.sub(%r{^/}, '')
    full_path = @target_dir.join(rel_path)
    puts "Generate #{full_path}"
    write_with_mkdir(full_path, html)
  end

  def create_rsync_keyfile(data)
    File.write(@rsync_keyfile, data)
    FileUtils.chmod(0o600, @rsync_keyfile)
  end

  private

  def write_with_mkdir(full_path, html)
    dir = File.dirname(full_path)
    FileUtils.mkdir_p(dir)
    File.write(full_path, html)
  end
end

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
    builder.create_rsync_keyfile(ENV.fetch('RSYNC_PASS_FILE', nil))
    src_dir = "#{builder.target_dir}/"
    cmd = "rsync -avhz -e \"ssh -i #{builder.rsync_keyfile}\" #{src_dir} aozora-renewal@aozora-renewal.sakura.ne.jp:/home/aozora-renewal/www"
    puts cmd
    system(cmd)
  end

  desc 'Build HTML files'
  task generate: :environment do
    url = Rails.application.routes.url_helpers
    builder = StaticPageBuilder.new

    builder.build_html(::Pages::Top::IndexPageComponent.new,
                       path: 'index.html')

    builder.build_html(::Pages::IndexPages::IndexTopPageComponent.new,
                       path: 'index_pages/index_top.html')

    builder.build_html(::Pages::IndexPages::IndexAllPageComponent.new,
                       path: 'index_pages/index_all.html')

    builder.build_html(::Pages::IndexPages::PersonAllPageComponent.new,
                       path: 'index_pages/person_all.html')

    Kana.each_sym_and_char do |id, kana|
      item_count = 20

      works = Work.published.with_title_firstchar(kana).order(:id).all

      total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
      (1..total_page).each do |page|
        pagy = Pagy.new(count: works.count, items: item_count, page: page)
        current_works = works.offset(pagy.offset).limit(pagy.items)

        builder.build_html(::Pages::IndexPages::WorkIndexPageComponent.new(id: id,
                                                                           kana: kana,
                                                                           pagy: pagy,
                                                                           works: current_works),
                           path: "index_pages/sakuhin_#{id}#{page}.html")
      end
    end

    Kana.each_sym_and_char do |id, kana| # rubocop:disable Style/CombinableLoops
      item_count = 20

      works = Work.unpublished.with_title_firstchar(kana).order(:id).all

      total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
      (1..total_page).each do |page|
        pagy = Pagy.new(count: works.count, items: item_count, page: page)
        current_works = works.offset(pagy.offset).limit(pagy.items)

        builder.build_html(::Pages::IndexPages::WorkInpIndexPageComponent.new(id: id,
                                                                              kana: kana,
                                                                              pagy: pagy,
                                                                              works: current_works),
                           path: "index_pages/sakuhin_inp_#{id}#{page}.html")
      end
    end

    current_year = Time.zone.now.year
    builder.build_html(::Pages::NewsEntries::IndexPageComponent.new(year: current_year),
                       path: 'soramoyou/soramoyouindex.html')

    begin_year = Pages::NewsEntries::IndexYearPageComponent::BEGIN_YEAR
    (begin_year..current_year).each do |year|
      builder.build_html(::Pages::NewsEntries::IndexYearPageComponent.new(year: year),
                         path: "soramoyou/soramoyou#{year}.html")
    end

    item_count = WhatsnewsController::ITEM_COUNT
    date = Time.zone.today

    works = Work.latest_published(until_date: date).order(published_on: :desc, id: :asc)
    total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
    (1..total_page).each do |page|
      pagy = Pagy.new(count: works.count, page: page, items: item_count)
      current_works = works.offset(pagy.offset).limit(pagy.items)
      path = url.whatsnew_index_pages_path(page: page, format: :html)
      builder.build_html(::Pages::Whatsnew::IndexPageComponent.new(date: date,
                                                                   pagy: pagy,
                                                                   works: current_works),
                         path: path)
    end

    prev_year = date.year - 1
    (::Pages::Whatsnew::IndexPageComponent::FIRST_YEAR..prev_year).each do |year|
      works = Work.latest_published(year: year).order(published_on: :desc, id: :asc)
      total_page = works.count.fdiv(item_count).ceil # 割り切れない場合は切り上げ
      (1..total_page).each do |page|
        pagy = Pagy.new(count: works.count, page: page, items: item_count)
        current_works = works.offset(pagy.offset).limit(pagy.items)
        path = url.whatsnew_year_index_pages_path(year_page: "#{year}_#{page}", format: :html)
        builder.build_html(::Pages::Whatsnew::IndexYearPageComponent.new(year: year,
                                                                         date: date,
                                                                         pagy: pagy,
                                                                         works: current_works),
                           path: path)
      end
    end

    Kana.each_column_key do |key|
      builder.build_html(::Pages::People::IndexPageComponent.new(id: key),
                         path: "index_pages/person_#{key}.html")

      builder.build_html(::Pages::IndexPages::PersonAllIndexPageComponent.new(id: key),
                         path: "index_pages/person_all_#{key}.html")

      builder.build_html(::Pages::IndexPages::PersonInpIndexPageComponent.new(id: key),
                         path: "index_pages/person_inp_#{key}.html")
    end

    Person.all.find_each do |person|
      builder.build_html(Pages::People::ShowPageComponent.new(person: person),
                         path: "index_pages/person#{person.id}.html")
      person.works.published.pluck(:id).each do |card_id|
        builder.build_html(Pages::Cards::ShowPageComponent.new(person_id: person.id,
                                                               card_id: card_id),
                           path: url.card_path(person_id: format('%06d', person.id),
                                               card_id: card_id,
                                               format: :html))
      end

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

  desc 'Generate all pages'
  task all: %i[environment build:clean build:prepare_assets build:copy_zip_files] do
    start_time = Time.current

    Rake::Task['build:generate'].invoke

    puts "Done: #{Time.current - start_time}"
  end
end
