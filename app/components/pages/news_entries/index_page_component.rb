# frozen_string_literal: true

module Pages
  module NewsEntries
    class IndexPageComponent < ViewComponent::Base
      attr_reader :news_entries

      def initialize(year:)
        @news_entries = NewsEntry.where('extract(year from published_on) = ?', year).order(published_on: :desc)
      end
    end
  end
end
