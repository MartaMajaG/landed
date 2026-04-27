class AddDescriptionToChecklistItems < ActiveRecord::Migration[8.1]
  def change
    add_column :checklist_items, :description, :text
  end
end
