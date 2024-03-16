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

    kana = Kana.new(id).to_char

    works = Work.published.with_title_firstchar(kana).order(:sortkey, :id).all

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

    kana = Kana.new(id).to_char

    works = Work.unpublished.with_title_firstchar(kana).order(:sortkey, :id).all

    pagy, current_works = pagy(works, item: 20, page: page)

    render ::Pages::IndexPages::WorkInpIndexPageComponent.new(id: id,
                                                              kana: kana,
                                                              pagy: pagy,
                                                              works: current_works)
  end

  def list_inp_show
    id, page = params[:id_page].split('_')
    author = Person.find(id)
    pagy, works = pagy(author.unpublished_works.order(:sortkey, :id), item: 20, page: page.to_i)

    render ::Pages::IndexPages::ListInpShowPageComponent.new(author: author,
                                                             pagy: pagy,
                                                             works: works)
  end
end
