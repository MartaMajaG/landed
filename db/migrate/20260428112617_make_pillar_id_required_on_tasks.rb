class MakePillarIdRequiredOnTasks < ActiveRecord::Migration[8.1]
  def change
    # Ensure Pillars exist BEFORE running this migration
    if Pillar.count == 0
      raise "You must run db:seed before this migration — no Pillars exist."
    end

    default_pillar = Pillar.first

    # Backfill missing pillar_id values BEFORE enforcing NOT NULL
    Task.where(pillar_id: nil).update_all(pillar_id: default_pillar.id)

    # Now it's safe to enforce NOT NULL
    change_column_null :tasks, :pillar_id, false
  end
end
