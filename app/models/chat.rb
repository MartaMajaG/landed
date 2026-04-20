class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :checklist_items
end
