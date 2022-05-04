# frozen_string_literal: true

class PeopleController < ApplicationController
  include Pagy::Backend

  def index
    render ::Pages::People::IndexPageComponent.new(id: params[:id].to_sym)
  end

  def show
    person = Person.find(params[:id])

    render ::Pages::People::ShowPageComponent.new(person: person)
  end
end
