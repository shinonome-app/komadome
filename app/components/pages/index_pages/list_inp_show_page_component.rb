# frozen_string_literal: true

module Pages
  module IndexPages
    class ListInpShowPageComponent < ViewComponent::Base
      attr_reader :id, :author, :pagy, :works

      def initialize(id:, author:, pagy:, works:)
        super

        @id = id
        @author = author
        @pagy = pagy
        @works = works
      end
    end
  end
end
