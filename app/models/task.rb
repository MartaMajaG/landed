class Task < ApplicationRecord
  belongs_to :city
  belongs_to :pillar, optional: true  # optional until seeds populate all pillar_ids
  has_many :checklist_items, dependent: :destroy

  validates :name, presence: true
end
