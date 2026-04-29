class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user    = current_user
    @profile = current_user.profile
    city_id  = current_user.profile.city_id

    # Pillar filter
    @pillars       = Pillar.where(city_id: city_id).order(:position)
    @active_pillar = params[:pillar].present? ? @pillars.find_by(slug: params[:pillar]) : nil

    # Base task scope
    base_tasks = @profile.tasks.includes(:pillar, :checklist_items)
    base_tasks = base_tasks.where(pillar_id: @active_pillar.id) if @active_pillar

    # Split completed vs incomplete
    all_tasks        = base_tasks.to_a
    incomplete       = all_tasks.reject { |t| t.completed_by?(current_user) }
    @completed_tasks = all_tasks.select { |t| t.completed_by?(current_user) }

    # Kanban columns from incomplete tasks only
    @urgent_tasks   = incomplete.select { |t| t.urgency == "high" }.first(2)
    @active_tasks   = incomplete.select { |t| t.urgency == "medium" }.first(2)
    @upcoming_tasks = incomplete.select { |t| t.urgency == "low" }.first(2)

    @urgent_count   = incomplete.count { |t| t.urgency == "high" }
    @active_count   = incomplete.count { |t| t.urgency == "medium" }
    @upcoming_count = incomplete.count { |t| t.urgency == "low" }

    # Pillar progress
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

    # Respond to AJAX tab switches
if params[:partial]
  if params[:tab] == "completed"
    completed = all_tasks.select { |t| t.completed_by?(current_user) }
    render partial: "kanban",
           locals: {
             urgent_tasks:   completed.select { |t| t.urgency == "high" }.first(2),
             active_tasks:   completed.select { |t| t.urgency == "medium" }.first(2),
             upcoming_tasks: completed.select { |t| t.urgency == "low" }.first(2),
             urgent_count:   completed.count  { |t| t.urgency == "high" },
             active_count:   completed.count  { |t| t.urgency == "medium" },
             upcoming_count: completed.count  { |t| t.urgency == "low" }
           }
  else
    render partial: "kanban",
           locals: {
             urgent_tasks:   @urgent_tasks,
             active_tasks:   @active_tasks,
             upcoming_tasks: @upcoming_tasks,
             urgent_count:   @urgent_count,
             active_count:   @active_count,
             upcoming_count: @upcoming_count
           }
  end  # closes if params[:tab] == "completed"
end    # closes if params[:partial]
  end    # closes def show
end    # closes class DashboardsController
