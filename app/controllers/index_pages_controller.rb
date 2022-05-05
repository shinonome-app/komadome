# frozen_string_literal: true

class IndexPagesController < ApplicationController
  include Pagy::Backend

  def index_top
    render ::Pages::IndexPages::IndexTopPageComponent.new
  end

  def index_all
    render ::Pages::IndexPages::IndexAllPageComponent.new
  end

  def person_all_index
    render ::Pages::IndexPages::PersonAllIndexPageComponent.new(id: params[:id].to_sym)
  end

  def person_all
    render ::Pages::IndexPages::PersonAllPageComponent.new
  end

  def person_inp_index
    render ::Pages::IndexPages::PersonInpIndexPageComponent.new(id: params[:id].to_sym)
  end

  def work_index
    params[:id_page] =~ /([kstnhmyrw]?[aiueo]|zz|nn)(\d+)/
    id = Regexp.last_match(1).to_sym
    page = Regexp.last_match(2)

    kana = roma2kana_char(id)

    works = if kana.empty?
              Work.published.where('sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]').order(:id).all
            else
              Work.published.where('sortkey ~ ?', "^#{kana}").order(:id).all
            end

    pagy, current_works = pagy(works, item: 20, page: page)

    render ::Pages::IndexPages::WorkIndexPageComponent.new(id: id,
                                                           kana: kana,
                                                           pagy: pagy,
                                                           works: current_works)
  end

  def work_inp_index
    params[:id_page] =~ /([kstnhmyrw]?[aiueo]|zz|nn)(\d+)/
    id = Regexp.last_match(1).to_sym
    page = Regexp.last_match(2)

    kana = roma2kana_char(id)

    works = if kana.empty?
              Work.unpublished.where('sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]').order(:id).all
            else
              Work.unpublished.where('sortkey ~ ?', "^#{kana}").order(:id).all
            end

    pagy, current_works = pagy(works, item: 20, page: page)

    render ::Pages::IndexPages::WorkInpIndexPageComponent.new(id: id,
                                                              kana: kana,
                                                              pagy: pagy,
                                                              works: current_works)
  end

  def list_inp_show
    id, page = params[:id_page].split('_')
    author = Person.find(id)
    pagy, works = pagy(author.unpublished_works.order(:id), item: 20, page: page.to_i)

    render ::Pages::IndexPages::ListInpShowPageComponent.new(id: id,
                                                             author: author,
                                                             pagy: pagy,
                                                             works: works)
  end

  private

  def roma2kana_chars(roma_id)
    ::KanaUtils.roma2kana_chars(roma_id)
  end

  def roma2kana_char(roma_id)
    ::KanaUtils.roma2kana_char(roma_id)
  end
end
