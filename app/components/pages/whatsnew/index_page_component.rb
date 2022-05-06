# frozen_string_literal: true

module Pages
  module Whatsnew
    class IndexPageComponent < ViewComponent::Base
      FIRST_YEAR = 2001

      attr_reader :pagy, :works, :date, :prev_year

      def initialize(pagy:, works:, date:)
        super
        @pagy = pagy
        @works = works
        @date = date
        @prev_year = date.year - 1
      end
    end
  end
end
