class Profile < ApplicationRecord
  belongs_to :user
  belongs_to :city, optional: true

  validates :user_id, uniqueness: true
  validates :city_id, presence: true, if: :onboardings_complete?
  validates :arrival_date, presence: true, if: :onboardings_complete?

  def onboardings_complete?
    city_id.present? && arrival_date.present?
  end
end
