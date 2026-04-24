class AddIsMandatoryToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :is_mandatory, :boolean
  end
end
