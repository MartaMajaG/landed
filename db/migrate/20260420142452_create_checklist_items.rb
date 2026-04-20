class CreateChecklistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :checklist_items do |t|
      t.string :title
      t.string :category
      t.integer :position
      t.references :city, null: false, foreign_key: true

      t.timestamps
    end
  end
end
