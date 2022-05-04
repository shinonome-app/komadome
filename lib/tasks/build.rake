# frozen_string_literal: true

require 'fileutils'

class StaticPageBuilder
  def initialize(target_dir)
    @target_dir = target_dir
  end

  def clean
    begin
      FileUtils.remove_entry_secure(@target_dir)
    rescue StandardError
      # noop
    end
  end

  def build_html(component, rel_path)
    html = ApplicationController.renderer.render(component, layout: nil)
    path = @target_dir.join(rel_path)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir)
    puts "Generate #{path}"
    File.write(path, html)
  end
end

namespace :build do
  desc 'Generate all people#show pages'
  task all: :environment do
    start_time = Time.current

    target_dir = Rails.root.join('build')
    builder = StaticPageBuilder.new(target_dir)

    builder.clean

    component = ::Pages::IndexPages::IndexTopPageComponent.new
    path = 'index_pages/index_top.html'
    builder.build_html(component, path)

    KanaUtils::ROMA2KANA_CHARS.keys.each do |key|
      component = ::Pages::People::IndexPageComponent.new(id: key)
      path = "index_pages/person_#{key}.html"
      builder.build_html(component, path)
    end

    Person.all.find_each do |person|
      component = Pages::People::ShowPageComponent.new(person: person)
      path = "index_pages/person#{person.id}.html"
      builder.build_html(component, path)
    end

    puts "Done: #{Time.current - start_time}"
  end
end
