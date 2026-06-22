# frozen_string_literal: true

module Pages
  module IndexPages
    # 登録全作家の集約ページ (person_all_all.html)。
    # 本家 https://www.aozora.gr.jp/index_pages/person_all_all.html に相当する。
    class PersonAllAllPageComponent < ViewComponent::Base
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
