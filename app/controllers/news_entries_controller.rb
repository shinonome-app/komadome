# frozen_string_literal: true

class NewsEntriesController < ApplicationController
  def index
    year = Time.zone.now.year

    render ::Pages::NewsEntries::IndexPageComponent.new(year: year)
  end

  def index_year
    year = params[:year].to_i

    render ::Pages::NewsEntries::IndexYearPageComponent.new(year: year)
  end
end
