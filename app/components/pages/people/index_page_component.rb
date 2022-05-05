# frozen_string_literal: true

module Pages
  module People
    class IndexPageComponent < ViewComponent::Base
      attr_reader :kana_all, :kana, :authors

      def initialize(id:)
        super

        @kana_all = roma2kana_chars(id)
        @kana = @kana_all[0]

        @authors = []
        if @kana_all.empty?
          @authors << Person.where('sortkey !~ ?', '^[あいうえおか-もやゆよら-ろわをんアイウエオカ-モヤユヨラ-ロワヲンヴ]')
        else
          @kana_all.each do |kana|
            @authors << Person.where('sortkey like ?', "#{kana}%")
          end
        end
      end

      private

      def roma2kana_chars(roma_id)
        ::KanaUtils.roma2kana_chars(roma_id)
      end

      def roma2kana_char(roma_id)
        ::KanaUtils.roma2kana_char(roma_id)
      end
    end
  end
end
