# frozen_string_literal: true

module Pages
  module IndexPages
    class WorkIndexPageComponent < ViewComponent::Base
      attr_reader :id, :kana, :pagy, :works

      def initialize(id:, kana:, pagy:, works:)
        @id = id
        @kana = kana
        @pagy = pagy
        @works = works
      end
    end
  end
end
