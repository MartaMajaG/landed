class MakePillarIdRequiredOnTasks < ActiveRecord::Migration[8.1]
  def change
    # Ensure at least one Pillar exists, bypassing validations
    default_pillar = Pillar.first

    unless default_pillar
      default_pillar = Pillar.new(name: "Default Pillar")
      default_pillar.save!(validate: false)  # <-- important
    end

    # Backfill missing pillar_id values BEFORE enforcing NOT NULL
    Task.where(pillar_id: nil).update_all(pillar_id: default_pillar.id)

    # Now it's safe to enforce NOT NULL
    change_column_null :tasks, :pillar_id, false
  end
end
