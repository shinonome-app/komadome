# frozen_string_literal: true

class IndexPagesController < ApplicationController
  ROMA2KANA = {a: 'アイウエオ',
               ka: 'カキクケコ',
               sa: 'サシスセソ',
               ta: 'タチツテト',
               na: 'ナニヌネノ',
               ha: 'ハヒフヘホ',
               ma: 'マミムメモ',
               ya: 'ヤユヨ',
               ra: 'ラリルレロ',
               wa: 'ワヲン',
               zz: '他'
              }

  def index_top
  end

  def person_index
    @kana_all = roma2kana(params[:id].to_sym).chars
    @kana = @kana_all[0]

    person1 = Person.where('last_name_kana like ?', 'あ%')
    person2 = Person.where('last_name_kana like ?', 'い%')
    person3 = Person.where('last_name_kana like ?', 'う%')
    person4 = Person.where('last_name_kana like ?', 'え%')
    person5 = Person.where('last_name_kana like ?', 'お%')
    @authors = [person1, person2, person3, person4, person5]
  end

  def person_show
    @author = Person.find(params[:id])
  end

  private

  def roma2kana(roma_id)
    ROMA2KANA[roma_id]
  end
end
