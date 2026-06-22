# frozen_string_literal: true

module Pages
  module IndexPages
    class PersonAllIndexPageComponent < ViewComponent::Base
      attr_reader :id, :kana, :kana_all, :authors

      def initialize(id:)
        super

        @id = id
        @kana_all = Kana.new(id).to_chars
        @kana = @kana_all[0]

        @authors = []
        if @kana_all.empty?
          @authors << Person.with_name_firstchar(nil)
        else
          @kana_all.each do |kana|
            @authors << Person.with_name_firstchar(kana)
          end
        end
      end
    end
  end
end
