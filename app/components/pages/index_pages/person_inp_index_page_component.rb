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
          @authors << Person.with_name_firstchar(nil).order(:sortkey, :sortkey2)
        else
          @kana_all.each do |kana|
            @authors << Person.with_name_firstchar(kana).order(:sortkey, :sortkey2)
          end
        end
      end
    end
  end
end
