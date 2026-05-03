# frozen_string_literal: true

module Pages
  module IndexPages
    class PersonInpAllPageComponent < ViewComponent::Base
      attr_reader :authors

      def initialize
        super

        @authors = {}
        Kana.each_column_chars do |chars|
          if chars.empty?
            @authors['その他'] = Person.with_unpublished_works_by_kana('その他')
          else
            chars.each do |kana|
              @authors[kana] = Person.with_unpublished_works_by_kana(kana)
            end
          end
        end
      end
    end
  end
end
