# frozen_string_literal: true

class TopController < ApplicationController
  def index
    render ::Pages::Top::IndexPageComponent.new
  end
end
