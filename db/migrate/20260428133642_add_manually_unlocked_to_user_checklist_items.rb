class AddManuallyUnlockedToUserChecklistItems < ActiveRecord::Migration[8.1]
  def change
    # Allows a user to override the soft-lock and unlock a step manually.
    add_column :user_checklist_items, :manually_unlocked, :boolean, null: false, default: false
  end
end
