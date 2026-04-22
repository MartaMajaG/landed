class AddMissingFieldsToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :document_type, :string
    add_column :documents, :advice, :text
  end
end
