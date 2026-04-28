class AddSoftLockFieldsToChecklistItems < ActiveRecord::Migration[8.1]
  def change
    # is_optional: drives the "Optional" badge in the UI
    add_column :checklist_items, :is_optional, :boolean, null: false, default: false
    # unlock_after_position: nil = always active; N = soft-locked until all positions <= N are completed
    add_column :checklist_items, :unlock_after_position, :integer, null: true
  end
end
