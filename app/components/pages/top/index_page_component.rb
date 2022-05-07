# frozen_string_literal: true

module Pages
  module Top
    class IndexPageComponent < ViewComponent::Base
      attr_reader :new_works, :new_works_published_on, :latest_news_entry

      def initialize
        super

        @new_works_published_on = Work.latest_published.order(published_on: :desc).first.published_on
        @new_works = Work.latest_published.where(published_on: new_works_published_on).order(id: :asc)
        @latest_news_entry = NewsEntry.published.order(published_on: :desc).first
      end
    end
  end
end
