# frozen_string_literal: true

module Pages
  module Top
    class IndexPageComponent < ViewComponent::Base
      attr_reader :new_works, :new_works_published_on, :latest_news_entry, :topics, :works_count, :works_copyright_count, :works_noncopyright_count

      def initialize
        super

        if Work.latest_published.blank?
          @new_works_published_on = Work.latest_published(year: Time.zone.now.year - 1).order(started_on: :desc).first.started_on
          @new_works = Work.latest_published(year: Time.zone.now.year - 1).where(started_on: new_works_published_on).order(id: :asc)
        else
          @new_works_published_on = Work.latest_published.order(started_on: :desc).first.started_on
          @new_works = Work.latest_published.where(started_on: new_works_published_on).order(id: :asc)
        end
        @latest_news_entry = NewsEntry.published.order(published_on: :desc).first
        @topics = NewsEntry.topics.order(published_on: :desc)

        @works_count = Work.published.count
        @works_copyright_count = Rails.cache.fetch("#{Work.last.cache_key_with_version}/copyright_count", expires_in: 24.hours) do
          Work.published.count { |work| work.copyright? }
        end
        @works_noncopyright_count = Rails.cache.fetch("#{Work.last.cache_key_with_version}/noncopyright_count", expires_in: 24.hours) do
          Work.published.count { |work| work.noncopyright? }
        end
      end
    end
  end
end
