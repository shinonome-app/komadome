# frozen_string_literal: true

module Pages
  module Whatsnew
    class IndexPageComponent < ViewComponent::Base
      attr_reader :pagy, :works, :date

      def initialize(pagy:, works:, date:)
        super
        @pagy = pagy
        @works = works
        @data = date
      end
    end
  end
end
