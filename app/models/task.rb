class Task < ApplicationRecord
  belongs_to :city
  belongs_to :pillar
  has_many :checklist_items, dependent: :destroy

  validates :name, presence: true

  def completed_by?(user)
    return false if checklist_items.empty?

    checklist_items.all? do |item|
      user.user_checklist_items.exists?(checklist_item: item, completed: true)
    end
  end
end
