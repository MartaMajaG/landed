class Profile < ApplicationRecord
  VISA_STATUSES = %w[student employment freelancer eu_citizen].freeze

  belongs_to :user
  belongs_to :city, optional: true

  has_many :tasks, through: :city

  validates :user_id, uniqueness: true
  validates :visa_status, inclusion: { in: VISA_STATUSES }, allow_blank: true

  def onboardings_complete?
    city_id.present? && visa_status.present? && !has_home.nil?
  end
end
