class Task < ApplicationRecord
  belongs_to :city
  has_many :checklist_items, dependent: :destroy

  validates :name, presence: true
end
