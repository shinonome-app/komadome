# frozen_string_literal: true

class IndexPagesController < ApplicationController
  include Pagy::Backend

  def index_top; end

  def index_all; end

  def whatsnew
    @pagy, @works = pagy(Work.order(:started_on).all, items: 50)
  end

  def whatsnew_year
    @year, @page = params[:year_page].split('_')
    logger.info("year:#{@year},#{params.inspect}")
    @pagy, @works = pagy(Work.with_year_and_status(@year, 1).order(:started_on).all, items: 80, page: @page)
  end

  def person_index
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

  def person_all_index
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

  def person_all
    @authors = {}
    KanaUtils::ROMA2KANA_CHARS.each_value do |value|
      if value.empty?
        @authors['その他'] = Person.where('sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]')
      else
        value.chars.each do |kana|
          @authors[kana] = Person.where('sortkey like ?', "#{kana}%")
        end
      end
    end
  end

  def person_show
    @author = Person.find(params[:id])
  end

  def person_inp_index
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

  def work_index
    params[:id_page] =~ /([kstnhmyrw]?[aiueo]|zz)(\d+)/
    @id = Regexp.last_match(1)
    @page = Regexp.last_match(2)

    @kana = roma2kana_char(@id.to_sym)

    @pagy, @works = if @kana.empty?
               pagy(Work.where('sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]').order(:id).all, item: 20, page: @page)
             else
               pagy(Work.where('sortkey ~ ?', "^#{@kana}").order(:id).all, item: 20, page: @page)
             end
  end

  def work_inp_index
    params[:id_page] =~ /([kstnhmyrw]?[aiueo]|zz)(\d+)/
    @id = Regexp.last_match(1)
    @page = Regexp.last_match(2)

    @kana = roma2kana_char(@id.to_sym)

    @pagy, @works = if @kana.empty?
               pagy(Work.where('sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]').order(:id).all, item: 20, page: @page)
             else
               pagy(Work.where('sortkey ~ ?', "^#{@kana}").order(:id).all, item: 20, page: @page)
             end
  end

  def list_person_all
    send_zip_file('list_person_all.zip')
  end

  def list_person_all_extended
    send_zip_file('list_person_all_extended.zip')
  end

  def list_person_all_utf8
    send_zip_file('list_person_all_utf8.zip')
  end

  def list_person_all_extended_utf8
    send_zip_file('list_person_all_extended_utf8.zip')
  end

  def list_inp_show
    @id, @page = params[:id_page].split('_')
    @author = Person.find(@id)
  end

  private

  def roma2kana_chars(roma_id)
    ::KanaUtils.roma2kana_chars(roma_id)
  end

  def roma2kana_char(roma_id)
    ::KanaUtils.roma2kana_char(roma_id)
  end

  def send_zip_file(filename)
    path = Rails.root.join('data', 'csv_zip', filename)
    stat = File.stat(path)
    send_file(path, filename:, length: stat.size)
  end
end
