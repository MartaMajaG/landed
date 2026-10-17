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

  # A deadline belongs to a person, not to a task. Tasks are shared by everyone
  # in a city, so the old stored due_date column was whichever user opened the
  # dashboard first, frozen for everyone after. It is no longer read or written:
  # each request works the date out from that user's own arrival date.
  attr_accessor :due_on

  # Deadlines count from arrival, or from the day the person joined Landed if
  # that is later, so nobody starts out with a board of overdue tasks.
  def due_date_for(profile, today: Date.today)
    arrival = profile&.arrival_date
    return nil unless arrival

    # created_at is stored in UTC; read it in local time like Date.today, or
    # late-evening sign-ups land a day early.
    joined = profile.created_at&.localtime&.to_date || today
    start  = [arrival, joined].max

    case urgency
    when "high"   then [start - 7.days, today].max
    when "medium" then start + 14.days
    when "low"    then start + 30.days
    end
  end

  def self.with_due_dates(tasks, profile)
    tasks.each { |task| task.due_on = task.due_date_for(profile) }
  end

  def overdue?(today: Date.today)
    due_on.present? && due_on < today
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
