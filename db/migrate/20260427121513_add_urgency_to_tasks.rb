class AddUrgencyToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :urgency, :string
  end
end
