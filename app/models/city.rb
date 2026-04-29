class City < ApplicationRecord
  has_many :profiles
  has_many :tasks

  validates :country, presence: true
  validates :name, presence: true
end
