class DropDocuments < ActiveRecord::Migration[8.1]
  def change
    drop_table :documents
  end
end
