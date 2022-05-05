# frozen_string_literal: true

module Pages
  module Whatsnew
    class IndexYearPageComponent < ViewComponent::Base
      attr_reader :pagy, :works, :year

      def initialize(pagy:, works:, year:)
        super
        @pagy = pagy
        @works = works
        @year = year
      end
    end
  end
end
