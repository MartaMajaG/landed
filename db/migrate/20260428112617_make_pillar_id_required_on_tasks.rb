class MakePillarIdRequiredOnTasks < ActiveRecord::Migration[8.1]
  def change
    # If no pillars exist yet, skip backfill and skip NOT NULL constraint
    return if Pillar.count == 0

    default_pillar = Pillar.first
    Task.where(pillar_id: nil).update_all(pillar_id: default_pillar.id)

    change_column_null :tasks, :pillar_id, false
  end
end
