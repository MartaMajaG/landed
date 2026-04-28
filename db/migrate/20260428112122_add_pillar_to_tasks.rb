class AddPillarToTasks < ActiveRecord::Migration[8.1]
  def change
    # Nullable first: existing Task rows have no Pillar yet.
    # The seeds will assign every Task a pillar_id.
    # A follow-up migration will enforce NOT NULL once all rows are populated.
    add_column :tasks, :pillar_id, :bigint, null: true
    add_index  :tasks, :pillar_id
    add_foreign_key :tasks, :pillars
  end
end
