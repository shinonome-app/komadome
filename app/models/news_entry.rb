# frozen_string_literal: true

# == Schema Information
#
# Table name: news_entries
#
#  id           :bigint           not null, primary key
#  body         :text             not null
#  flag         :boolean          not null
#  published_on :date
#  title        :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class NewsEntry < ApplicationRecord
  scope :published, ->(date = Time.zone.today) { where('published_on <= ?', date) }

  validates :title, :body, :flag, presence: true
end
