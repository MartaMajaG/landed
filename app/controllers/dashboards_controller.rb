class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user    = current_user
    @profile = current_user.profile
    city_id  = current_user.profile.city_id

    # Kanban columns — max 2 cards shown per column, total count for badge + "see more"
    @urgent_tasks   = @profile.tasks.includes(:pillar).where(urgency: "high").limit(2)
    @active_tasks   = @profile.tasks.includes(:pillar).where(urgency: "medium").limit(2)
    @upcoming_tasks = @profile.tasks.includes(:pillar).where(urgency: "low").limit(2)

    @urgent_count   = @profile.tasks.where(urgency: "high").count
    @active_count   = @profile.tasks.where(urgency: "medium").count
    @upcoming_count = @profile.tasks.where(urgency: "low").count

    # @tasks kept for the Pillar Cards progress section (all tasks, no limit)
    @tasks = @profile.tasks.includes(:pillar)

    # Pillar cards section — ordered by position (1–4)
    @pillars = Pillar.where(city_id: city_id).order(:position)

    # Aggregate subtask progress per pillar in 3 queries (no N+1)
    ci_rows = ChecklistItem.joins(:task)
                           .where(tasks: { city_id: city_id })
                           .pluck(:id, "tasks.pillar_id")

    completed_ids = current_user.user_checklist_items
                                .where(completed: true)
                                .pluck(:checklist_item_id).to_set

    @pillar_progress = Hash.new { |h, k| h[k] = { total: 0, done: 0 } }
    ci_rows.each do |ci_id, pillar_id|
      @pillar_progress[pillar_id][:total] += 1
      @pillar_progress[pillar_id][:done]  += 1 if completed_ids.include?(ci_id)
    end
  end

end

