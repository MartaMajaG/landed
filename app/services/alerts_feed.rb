# Everything with a deadline in the next 30 days (or already overdue) that the
# user still has to act on: unfinished relocation tasks and scanned documents.
# Built from existing data, so there's nothing extra to store or keep in sync.
class AlertsFeed
  WINDOW = 30 # days ahead

  Item = Struct.new(:kind, :title, :category, :category_slug, :due_date, :record, keyword_init: true)

  attr_reader :today

  def initialize(user, today: Date.current)
    @user  = user
    @today = today
  end

  def items
    @items ||= (task_items + document_items).sort_by(&:due_date)
  end

  def overdue   = items.select { |i| i.due_date < today }
  def this_week = items.select { |i| i.due_date >= today && i.due_date <= today + 7 }
  def coming_up = items.select { |i| i.due_date > today + 7 }

  # Shown as a dot on the bell: things that need action now or this week
  def attention_count
    items.count { |i| i.due_date <= today + 7 }
  end

  private

  def task_items
    profile = @user.profile
    return [] unless profile&.city_id

    Task.assign_due_dates(profile)
    profile.tasks
           .includes(:pillar, :checklist_items)
           .where.not(due_date: nil)
           .where("due_date <= ?", today + WINDOW)
           .reject { |t| t.completed_by?(@user) }
           .map do |t|
             Item.new(kind: :task, title: t.name, category: t.pillar&.name,
                      category_slug: t.pillar&.slug, due_date: t.due_date, record: t)
           end
  end

  def document_items
    @user.chats
         .where.not(deadline: nil)
         .where("deadline <= ?", today + WINDOW)
         .map do |c|
           Item.new(kind: :document, title: c.title.to_s.sub(/\s*[\[(].*[\])]\s*\z/, "").strip,
                    category: "Scanned document", category_slug: "scanned_document",
                    due_date: c.deadline, record: c)
         end
  end
end
