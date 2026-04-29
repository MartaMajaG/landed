class CleanupDuplicateCities < ActiveRecord::Migration[8.1]
  def up
    # Reassign any records still pointing to the old Munich (city_id = 2)
    say "Reassigning city_id 2 → 5"

    # Update tasks
    Task.where(city_id: 2).update_all(city_id: 5)

    # Update pillars
    Pillar.where(city_id: 2).update_all(city_id: 5)

    # Update profiles (if any)
    Profile.where(city_id: 2).update_all(city_id: 5)

    # Delete old cities (1, 2, 3)
    say "Deleting old city records: 1, 2, 3"
    City.where(id: [1, 2, 3]).destroy_all
  end

  def down
    # No-op: this cleanup is not reversible
    say "No rollback for CleanupDuplicateCities"
  end
end
