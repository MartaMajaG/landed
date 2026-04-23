class AddAiResultsToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :title, :string
    add_column :chats, :amount, :float
    add_column :chats, :deadline, :date
    add_column :chats, :urgency, :string
    add_column :chats, :document_type, :string
    add_column :chats, :advice, :text
  end
end
