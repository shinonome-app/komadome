# frozen_string_literal: true

class WhatsnewsController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @works = pagy(Work.order(:started_on).all, items: 50)
  end

  def index_year
    @year, @page = params[:year_page].split('_')
    logger.info("year:#{@year},#{params.inspect}")
    @pagy, @works = pagy(Work.with_year_and_status(@year, 1).order(:started_on).all, items: 80, page: @page)
  end
end
