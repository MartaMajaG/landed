class UserChecklistItem < ApplicationRecord
  belongs_to :checklist_item
  belongs_to :user

  validates :user, :checklist_item, presence: true
end
