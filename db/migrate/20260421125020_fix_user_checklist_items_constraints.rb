class FixUserChecklistItemsConstraints < ActiveRecord::Migration[7.1]
  def change
    change_column_default :user_checklist_items, :completed, from: nil, to: false
    change_column_null :user_checklist_items, :completed, false, false

    add_index :user_checklist_items,
              [:user_id, :checklist_item_id],
              unique: true,
              name: "index_user_checklist_items_on_user_id_and_checklist_item_id"
  end
end
