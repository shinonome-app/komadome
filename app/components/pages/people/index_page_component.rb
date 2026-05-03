# frozen_string_literal: true

module Pages
  module People
    class IndexPageComponent < ViewComponent::Base
      attr_reader :kana_all, :kana, :authors

      def initialize(id:)
        super

        @kana_all = Kana.new(id).to_chars
        @kana = @kana_all[0]

        @authors = []
        if @kana_all.empty?
          @authors << Person.with_name_firstchar(nil).order(:sortkey, :sortkey2, :id)
        else
          @kana_all.each do |kana|
            @authors << Person.with_name_firstchar(kana).order(:sortkey, :sortkey2, :id)
          end
        end
      end
    end
  end
end
