# frozen_string_literal: true

class NewsEntriesController < ApplicationController
  def index
    @news_entries = NewsEntry.where("extract(year from published_on) = ?", Time.zone.now.year).order(published_on: :desc)
  end

  def index_year
    @year = params[:year].to_i
    @news_entries = NewsEntry.where("extract(year from published_on) = ?", params[:year]).order(published_on: :desc)
  end
end
