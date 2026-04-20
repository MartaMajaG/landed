class AddTaskToChecklistItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :checklist_items, :task, null: false, foreign_key: true
  end
end
