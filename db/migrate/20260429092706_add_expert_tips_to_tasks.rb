class AddExpertTipsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :expert_tips, :jsonb, default: [], null: false
  end
end
