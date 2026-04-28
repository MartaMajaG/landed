class Pillar < ApplicationRecord
  belongs_to :city
  has_many :tasks, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :position, presence: true

  # Subtasks (ChecklistItems) reachable from the Pillar level
  # through the Main Tasks. Used for aggregated progress calculation.
  def checklist_items
    ChecklistItem.joins(:task).where(tasks: { pillar_id: id })
  end
end
