class City < ApplicationRecord
  has_many :profiles
  has_many :checklist_items, dependent: :destroy

  validates :country, presence: true
  validates :name, presence: true
end
