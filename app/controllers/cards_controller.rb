# frozen_string_literal: true

class CardsController < ApplicationController
  def card_show
    @work = Work.find(params[:card_id])
  end
end
