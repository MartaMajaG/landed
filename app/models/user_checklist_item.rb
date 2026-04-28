class UserChecklistItem < ApplicationRecord
  belongs_to :checklist_item
  belongs_to :user

  validates :user_id, uniqueness: { scope: :checklist_item_id }

  scope :manually_unlocked, -> { where(manually_unlocked: true) }
end
