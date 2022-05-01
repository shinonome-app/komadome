# frozen_string_literal: true

class TopController < ApplicationController
  def index
    @new_works_published_on = Work.published.order(started_on: :desc).first.started_on
    @new_works = Work.published.where(started_on: @new_works_published_on)
  end
end
