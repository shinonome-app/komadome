# frozen_string_literal: true

class CardsController < ApplicationController
  def show
    @work = Work.joins(:work_people).where('works.id = ? AND work_people.person_id = ?', params[:card_id].to_i, params[:person_id].to_i).first
    @booklog_url = "http://booklog.jp/item/7/#{@work.id}"
    @voyger_url = "http://aozora.binb.jp/reader/main.html?cid=#{@work.id}"
    @airzoshi_url = "https://www.satokazzz.com/airzoshi/reader.php?action=aozora&id=#{@work.id}"
    @rodoku_url = "https://www.google.co.jp/search?hl=ja&source=hp&q=青空文庫+朗読+#{@work.title}"
  end
end
