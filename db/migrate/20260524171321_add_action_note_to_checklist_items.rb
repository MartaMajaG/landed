class AddActionNoteToChecklistItems < ActiveRecord::Migration[8.0]
  def change
    add_column :checklist_items, :action_note, :text
  end
end
