class RemoveChecklistIdFromChats < ActiveRecord::Migration[8.1]
  def change
    remove_column :chats, :checklist_items_id, :integer
  end
end
