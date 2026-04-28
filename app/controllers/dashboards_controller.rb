class DashboardsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @user    = current_user
    @profile = current_user.profile
    city_id  = current_user.profile.city_id

    # Eager-load pillar so pill tags read task.pillar.name without N+1
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

