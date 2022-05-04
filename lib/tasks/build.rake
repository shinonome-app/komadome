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

  def force_clean
    FileUtils.remove_entry_secure(@target_dir, :force)
  end

  def build_html(component, path:)
    html = ApplicationController.renderer.render(component, layout: nil)
    full_path = @target_dir.join(path)
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

    builder = StaticPageBuilder.new

    builder.force_clean

    builder.copy_precompiled_assets

    builder.build_html(::Pages::IndexPages::IndexTopPageComponent.new,
                       path: 'index_pages/index_top.html')

    KanaUtils::ROMA2KANA_CHARS.keys.each do |key|
      builder.build_html(::Pages::People::IndexPageComponent.new(id: key),
                         path: "index_pages/person_#{key}.html")
    end

    Person.all.find_each do |person|
      builder.build_html(Pages::People::ShowPageComponent.new(person: person),
                         path: "index_pages/person#{person.id}.html")
    end

    puts "Done: #{Time.current - start_time}"
  end
end
