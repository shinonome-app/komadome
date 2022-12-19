# frozen_string_literal: true

module Pages
  module Top
    class IndexPageComponent < ViewComponent::Base
      attr_reader :new_works, :new_works_published_on, :latest_news_entry, :topics, :works_count, :works_copyright_count, :works_noncopyright_count

      def initialize
        super

        @new_works_published_on = Work.latest_published.order(started_on: :desc).first.started_on
        @new_works = Work.latest_published.where(started_on: new_works_published_on).order(id: :asc)
        @latest_news_entry = NewsEntry.published.order(published_on: :desc).first
        @topics = NewsEntry.topics.order(published_on: :desc)

        @works_count = Work.published.count
        @works_copyright_count = Work.published.select { |work| work.copyright? }.count
        @works_noncopyright_count = Work.published.select { |work| work.noncopyright? }.count
      end
    end
  end
end
