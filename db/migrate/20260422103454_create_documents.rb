class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :title
      t.float :amount
      t.date :deadline
      t.string :urgency
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
