class AddDocumentTypeIdToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_reference :documents, :document_type, null: true, foreign_key: true
  end
end
