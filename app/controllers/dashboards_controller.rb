class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user    = current_user
    @profile = current_user.profile
    city_id  = current_user.profile.city_id

    # Pillar filter — optional URL param (?pillar=housing_and_registration)
    @pillars       = Pillar.where(city_id: city_id).order(:position)
    @active_pillar = params[:pillar].present? ? @pillars.find_by(slug: params[:pillar]) : nil

    # Base task scope — filtered by pillar if one is selected
    base_tasks = @profile.tasks.includes(:pillar)
    base_tasks = base_tasks.where(pillar_id: @active_pillar.id) if @active_pillar

    # Kanban columns — all tasks loaded, column scrolls when count exceeds visible area
    @urgent_tasks   = base_tasks.where(urgency: "high")
    @active_tasks   = base_tasks.where(urgency: "medium")
    @upcoming_tasks = base_tasks.where(urgency: "low")

    @urgent_count   = @urgent_tasks.size
    @active_count   = @active_tasks.size
    @upcoming_count = @upcoming_tasks.size

    # Pillar progress — aggregate subtask completion per pillar (3 queries, no N+1)
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

