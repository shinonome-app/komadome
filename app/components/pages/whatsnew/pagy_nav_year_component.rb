# frozen_string_literal: true

module Pages
  module Whatsnew
    class PagyNavYearComponent < ViewComponent::Base
      attr_reader :pagy, :year

      def initialize(pagy:, year:)
        super
        @pagy = pagy
        @year = year
      end
    end
  end
end
