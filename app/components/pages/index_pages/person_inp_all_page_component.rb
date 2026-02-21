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
            @authors['その他'] = Person.joins(:works).merge(Work.unpublished)
                                    .where('people.sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]')
                                    .distinct.order(:sortkey, :sortkey2, :id)
          else
            chars.each do |kana|
              @authors[kana] = Person.joins(:works).merge(Work.unpublished)
                                     .where('people.sortkey like ?', "#{kana}%")
                                     .distinct.order(:sortkey, :sortkey2, :id)
            end
          end
        end
      end
    end
  end
end
