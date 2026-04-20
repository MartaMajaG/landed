class RemoveCityIdFromChecklistItems < ActiveRecord::Migration[8.1]
  def change
    remove_column :checklist_items, :city_id, :integer
  end
end
