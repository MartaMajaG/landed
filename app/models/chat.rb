class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :checklist_item

  # Allows the chat to have one PDF attached for processing
  has_one_attached :pdf
end
