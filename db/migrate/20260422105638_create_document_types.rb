class CreateDocumentTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :document_types do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.jsonb :master_data, default: {}, null: false

      t.timestamps
    end

    # Explicit index for slugs to ensure fast lookups by the Matcher Service
    add_index :document_types, :slug, unique: true
  end
end
