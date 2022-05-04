# frozen_string_literal: true

require 'fileutils'

class StaticPageBuilder
  class << self
    def build_html(component, path)
      html = ApplicationController.renderer.render(component, layout: nil)
      puts "Generate #{path}"
      File.write(path, html)
    end
  end
end

namespace :build do
  desc 'Generate all people#show pages'
  task all: :environment do
    start_time = Time.current

    target_dir = Rails.root.join('build')
    begin
      FileUtils.remove_entry_secure(target_dir)
    rescue StandardError
      # noop
    end
    FileUtils.mkdir(target_dir)
    FileUtils.mkdir(target_dir.join('index_pages'))

    component = ::Pages::IndexPages::IndexTopPageComponent.new
    path = target_dir.join('index_pages/index_top.html')
    StaticPageBuilder.build_html(component, path)

    KanaUtils::ROMA2KANA_CHARS.keys.each do |key|
      component = ::Pages::People::IndexPageComponent.new(id: key)
      path = target_dir.join("index_pages/person_#{key}.html")
      StaticPageBuilder::build_html(component, path)
    end

    Person.all.find_each do |person|
      component = Pages::People::ShowPageComponent.new(person: person)
      path = target_dir.join("index_pages/person#{person.id}.html")
      StaticPageBuilder::build_html(component, path)
    end

    puts "Done: #{Time.current - start_time}"
  end
end
