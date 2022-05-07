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
            @authors['その他'] = Person.where('sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]')
          else
            chars.each do |kana|
              @authors[kana] = Person.where('sortkey like ?', "#{kana}%")
            end
          end
        end
      end
    end
  end
end
