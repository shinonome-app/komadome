# frozen_string_literal: true

class DownloadsController < ApplicationController
  include Pagy::Backend

  def list_person_all
    send_zip_file('list_person_all.zip')
  end

  def list_person_all_extended
    send_zip_file('list_person_all_extended.zip')
  end

  def list_person_all_utf8
    send_zip_file('list_person_all_utf8.zip')
  end

  def list_person_all_extended_utf8
    send_zip_file('list_person_all_extended_utf8.zip')
  end

  private

  def send_zip_file(filename)
    path = Rails.root.join('data', 'csv_zip', filename)
    stat = File.stat(path)
    send_file(path, filename:, length: stat.size)
  end
end
