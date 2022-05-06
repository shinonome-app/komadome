# frozen_string_literal: true

module Pages
  module Whatsnew
    class IndexYearPageComponent < ViewComponent::Base
      attr_reader :pagy, :works, :year, :date

      def initialize(pagy:, works:, year:, date:)
        super
        @pagy = pagy
        @works = works
        @year = year
        @date = date
      end
    end
  end
end
