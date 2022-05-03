# frozen_string_literal: true

module Pages
  module People
    class ShowPageComponent < ViewComponent::Base
      attr_reader :kana_fragment, :kana, :author

      def initialize(person:)
        super
        @author = person
        @kana, index = KanaUtils.kana2roma_chars(@author.sortkey.first)
        @kana_fragment = "sec#{index + 1}"
      end
    end
  end
end
