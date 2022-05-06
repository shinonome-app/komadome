# frozen_string_literal: true

class WhatsnewsController < ApplicationController
  # TODO: 新着情報に載せるタイミングを決める
  # とりあえずは去年にしないとseedデータ上の問題がある…
  LIMIT_DATE = '2021-01-01'
  ITEM_COUNT = 50

  include Pagy::Backend

  def index
    date = LIMIT_DATE
    works = Work.where('published_on IS NOT NULL AND published_on >= ?', date).order(published_on: :desc, id: :asc)
    pagy, current_works = pagy(works, items: ITEM_COUNT)

    render ::Pages::Whatsnew::IndexPageComponent.new(date: date,
                                                     pagy: pagy,
                                                     works: current_works)
  end

  def index_year
    year, page = params[:year_page].split('_')
    begin_date, end_date = begin_and_end_date(year)
    works = Work.with_year_and_status(year, 1).where('published_on IS NOT NULL AND published_on >= ? AND published_on < ?', begin_date, end_date).order(published_on: :desc, id: :asc)
    pagy, current_works = pagy(works, items: 50, page: page)

    render ::Pages::Whatsnew::IndexYearPageComponent.new(year: year,
                                                         pagy: pagy,
                                                         works: current_works)
  end

  private

  def begin_and_end_date(year)
    begin_date = "#{year}-01-01"
    end_date = "#{year.to_i + 1}-01-01"

    [begin_date, end_date]
  end
end
