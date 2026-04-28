class MakePillarIdRequiredOnTasks < ActiveRecord::Migration[8.1]
  def change
    # Safety guard: abort if any Task still has no Pillar assigned.
    # Run db:seed before this migration if it fails.
    if Task.where(pillar_id: nil).exists?
      raise "Cannot enforce NOT NULL on tasks.pillar_id — #{Task.where(pillar_id: nil).count} task(s) still have no pillar. Run db:seed first."
    end

    change_column_null :tasks, :pillar_id, false
  end
end
