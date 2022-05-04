# frozen_string_literal: true

module Pages
  module IndexPages
    class PersonAllPageComponent < ViewComponent::Base
      attr_reader :authors

      def initialize
        @authors = {}
        KanaUtils::ROMA2KANA_CHARS.each_value do |value|
          if value.empty?
            @authors['その他'] = Person.where('sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]')
          else
            value.chars.each do |kana|
              @authors[kana] = Person.where('sortkey like ?', "#{kana}%")
            end
          end
        end
      end
    end
  end
end
