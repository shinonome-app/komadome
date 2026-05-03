# frozen_string_literal: true

module Pages
  module IndexPages
    class PersonAllPageComponent < ViewComponent::Base
      attr_reader :authors

      def initialize
        super

        @authors = {}
        Kana.each_column_chars do |chars|
          if chars.empty?
            @authors['その他'] = Person.with_name_firstchar('その他')
          else
            chars.each do |kana|
              @authors[kana] = Person.with_name_firstchar(kana)
            end
          end
        end
      end
    end
  end
end
