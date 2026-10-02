class ChecklistItem < ApplicationRecord
  belongs_to :task

  has_many :user_checklist_items, dependent: :destroy
  has_many :chats

  validates :title, :category, presence: true

  scope :optional,  -> { where(is_optional: true) }
  scope :mandatory, -> { where(is_optional: false) }

  # Returns true if this step should be displayed as soft-locked for a given user.
  # A step is soft-locked when:
  #   1. It has an unlock_after_position set
  #   2. The user has NOT manually unlocked it
  #   3. At least one prerequisite step (position <= unlock_after_position) is not yet completed
  def soft_locked_for?(user_checklist_items_by_id, manually_unlocked_ids, all_task_items)
    return false if unlock_after_position.nil?
    return false if manually_unlocked_ids.include?(id)

    prerequisites = all_task_items.select { |i| i.position <= unlock_after_position }
    prerequisites.any? { |prereq| !user_checklist_items_by_id[prereq.id]&.completed }
  end
end
