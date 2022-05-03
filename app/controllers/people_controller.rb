# frozen_string_literal: true

class PeopleController < ApplicationController
  include Pagy::Backend

  def index
    @kana_all = roma2kana_chars(params[:id].to_sym)
    @kana = @kana_all[0]

    @authors = []
    if @kana_all.empty?
      @authors << Person.where('sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]')
    else
      @kana_all.each do |kana|
        @authors << Person.where('sortkey like ?', "#{kana}%")
      end
    end
  end

  def show
    person = Person.find(params[:id])

    render ::Pages::People::ShowPageComponent.new(person: person)
  end

  private

  def roma2kana_chars(roma_id)
    ::KanaUtils.roma2kana_chars(roma_id)
  end

  def roma2kana_char(roma_id)
    ::KanaUtils.roma2kana_char(roma_id)
  end
end
