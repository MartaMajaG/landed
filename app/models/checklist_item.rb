class ChecklistItem < ApplicationRecord
  belongs_to :task

  has_many :user_checklist_items, dependent: :destroy
  has_many :chats

  validates :title, :category, presence: true
  # validates :position, numericality: { only_integer: true }
end
