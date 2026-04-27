class AddDetailsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :description, :text
    add_column :tasks, :why_it_matters, :text
    add_column :tasks, :category, :string
  end
end
