# frozen_string_literal: true

class CardsController < ApplicationController
  def show
    @work = Work.joins(:work_people).where('works.id = ? AND work_people.person_id = ?', params[:card_id].to_i, params[:person_id].to_i).first
  end
end
