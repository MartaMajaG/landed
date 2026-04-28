class CreatePillars < ActiveRecord::Migration[8.1]
  def change
    create_table :pillars do |t|
      t.string  :name,        null: false
      t.string  :slug,        null: false
      t.text    :description
      t.string  :icon
      t.integer :position,    null: false, default: 0
      t.bigint  :city_id,     null: false

      t.timestamps
    end

    add_index :pillars, :slug,               unique: true
    add_index :pillars, :city_id
    add_foreign_key :pillars, :cities
  end
end
