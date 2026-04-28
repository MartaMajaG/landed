class Task < ApplicationRecord
  belongs_to :city
  belongs_to :pillar
  has_many :checklist_items, dependent: :destroy

  validates :name, presence: true
end
