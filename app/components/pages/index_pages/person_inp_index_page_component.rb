# frozen_string_literal: true

module Pages
  module IndexPages
    class PersonInpIndexPageComponent < ViewComponent::Base
      attr_reader :id, :kana, :kana_all, :authors

      def initialize(id:)
        super

        @id = id
        @kana_all = Kana.new(id).to_chars
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
    end
  end
end
