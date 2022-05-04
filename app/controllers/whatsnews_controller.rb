# frozen_string_literal: true

class WhatsnewsController < ApplicationController
  # TODO: 新着情報に載せるタイミングを決める
  # とりあえずは去年にしないとseedデータ上の問題がある…
  LIMIT_DATE = '2021-01-01'
  ITEM_COUNT = 50

  include Pagy::Backend

  def index
    date = LIMIT_DATE
    works = Work.order(started_on: :desc).where('started_on >= ?', date)
    pagy, current_works = pagy(works, items: ITEM_COUNT)

    render ::Pages::Whatsnew::IndexPageComponent.new(date: date,
                                                     pagy: pagy,
                                                     works: current_works)
  end

  def index_year
    @year, @page = params[:year_page].split('_')
    logger.info("year:#{@year},#{params.inspect}")
    begin_date = "#{@year}-01-01"
    end_date = "#{@year.to_i + 1}-01-01"
    @pagy, @works = pagy(Work.with_year_and_status(@year, 1).where('started_on >= ? AND started_on < ?', begin_date, end_date).order(started_on: :desc), items: 50, page: @page)
  end
end
