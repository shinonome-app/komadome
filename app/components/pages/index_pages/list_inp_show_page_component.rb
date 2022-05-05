# frozen_string_literal: true

module Pages
  module IndexPages
    class ListInpShowPageComponent < ViewComponent::Base
      attr_reader :author, :pagy, :works

      def initialize(author:, pagy:, works:)
        super

        @author = author
        @pagy = pagy
        @works = works
      end
    end
  end
end
