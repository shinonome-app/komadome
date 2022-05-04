# frozen_string_literal: true

module Pages
  module Top
    class IndexPageComponent < ViewComponent::Base
      attr_reader :new_works, :new_works_published_on

      def initialize
        @new_works_published_on = Work.published.order(started_on: :desc).first.started_on
        @new_works = Work.published.where(started_on: new_works_published_on)
      end
    end
  end
end
