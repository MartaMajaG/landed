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

  def self.assign_due_dates(profile)
    arrival = profile.arrival_date
    return unless arrival

    profile.tasks.where(due_date: nil).each do |task|
      task.update(due_date: case task.urgency
        when "high" then [arrival - 7.days, Date.today].max
        when "medium" then arrival + 14.days
        when "low"    then arrival + 30.days
      end)
    end
  end

  def calendar_category
    case pillar&.slug
    when /housing/ then "housing"
    when /finance/ then "financial"
    when /health/  then "health_and_insurance"
    else "admin"
    end
  end
end
