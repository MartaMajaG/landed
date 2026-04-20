class CreateUserChecklistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :user_checklist_items do |t|
      t.boolean :completed
      t.references :checklist_item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
