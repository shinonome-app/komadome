# frozen_string_literal: true

# == Schema Information
#
# Table name: base_people
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  original_person_id :bigint           not null
#  person_id          :bigint           not null
#
# Indexes
#
#  index_base_people_on_original_person_id  (original_person_id)
#  index_base_people_on_person_id           (person_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (original_person_id => people.id)
#  fk_rails_...  (person_id => people.id)
#

# 基本人物
class BasePerson < ApplicationRecord
  belongs_to :person
  belongs_to :original_person, class_name: 'Person'

  validates :person_id, uniqueness: { message: I18n.t('errors.base_person.unique') }

  validate :person_and_original_persion_must_be_different

  def person_and_original_persion_must_be_different
    errors.add(:person_id, I18n.t('errors.base_person.same_person')) if original_person_id == person_id
  end

  def name
    "#{last_name} #{first_name}"
  end

  def name_kana
    "#{last_name_kana} #{first_name_kana}"
  end
end
