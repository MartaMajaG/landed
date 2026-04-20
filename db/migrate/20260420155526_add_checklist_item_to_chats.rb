class AddChecklistItemToChats < ActiveRecord::Migration[8.1]
  def change
    add_reference :chats, :checklist_item, null: false, foreign_key: true
  end
end
