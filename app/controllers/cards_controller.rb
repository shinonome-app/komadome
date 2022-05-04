# frozen_string_literal: true

class CardsController < ApplicationController
  def show
    person_id = params[:person_id]
    card_id = params[:card_id]

    render ::Pages::Cards::ShowPageComponent.new(person_id: person_id,
                                                 card_id: card_id)
  end
end
