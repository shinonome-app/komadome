# frozen_string_literal: true

module Pages
  module IndexPages
    class PagyNavInpComponent < ViewComponent::Base
      attr_reader :id, :pagy

      def initialize(id:, pagy:)
        super
        @id = id
        @pagy = pagy
      end
    end
  end
end
