# frozen_string_literal: true

require 'fileutils'

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

    Person.all.find_each do |person|
      component = Pages::People::ShowPageComponent.new(person: person)
      html = ApplicationController.renderer.render(component, layout: nil)
      path = target_dir.join("index_pages/person#{person.id}.html")
      puts "Generate #{path}"
      File.write(path, html)
    end

    puts "Done: #{Time.current - start_time}"
  end
end
