class AddNameToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :name, :string
  end
end
