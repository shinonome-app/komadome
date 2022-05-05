# frozen_string_literal: true

module Pages
  module Whatsnew
    class PagyNavComponent < ViewComponent::Base
      attr_reader :pagy

      def initialize(pagy:)
        super
        @pagy = pagy
      end
    end
  end
end
