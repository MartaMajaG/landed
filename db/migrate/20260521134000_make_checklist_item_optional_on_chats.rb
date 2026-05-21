class MakeChecklistItemOptionalOnChats < ActiveRecord::Migration[8.1]
  def change
    change_column_null :chats, :checklist_item_id, true
  end
end
