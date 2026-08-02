class CreateProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :providers do |t|
      t.string  :name, null: false
      t.string  :normalized_name, null: false
      t.string  :phone
      t.string  :website
      t.string  :contact_url
      t.string  :source_url
      t.integer :contact_status, null: false, default: 0
      t.datetime :looked_up_at

      t.timestamps
    end

    add_index :providers, :normalized_name, unique: true
    add_reference :chats, :provider, null: true, foreign_key: true
  end
end
