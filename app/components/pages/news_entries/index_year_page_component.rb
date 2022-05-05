# frozen_string_literal: true

module Pages
  module NewsEntries
    class IndexYearPageComponent < ViewComponent::Base
      BEGIN_YEAR = 1997

      attr_reader :news_entries, :year

      def initialize(year:)
        @year = year
        @news_entries = NewsEntry.where('extract(year from published_on) = ?',
                                        @year).order(published_on: :desc)
      end
    end
  end
end
