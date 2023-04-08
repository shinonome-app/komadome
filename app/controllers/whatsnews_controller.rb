# frozen_string_literal: true

class WhatsnewsController < ApplicationController
  ITEM_COUNT = 50

  include Pagy::Backend

  def index
    date = Time.zone.today
    works = Work.latest_published(until_date: date).order(started_on: :desc, id: :asc)
    pagy, current_works = pagy(works, items: ITEM_COUNT)

    render ::Pages::Whatsnew::IndexPageComponent.new(date: date,
                                                     pagy: pagy,
                                                     works: current_works)
  end

  def index_year
    year, page = params[:year_page].split('_')
    date = Time.zone.today
    works = Work.latest_published(year: year).order(started_on: :desc, id: :asc)
    pagy, current_works = pagy(works, items: ITEM_COUNT, page: page)

    render ::Pages::Whatsnew::IndexYearPageComponent.new(year: year,
                                                         date: date,
                                                         pagy: pagy,
                                                         works: current_works)
  end
end
