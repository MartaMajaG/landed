class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user    = current_user
    @profile = current_user.profile
    city_id  = current_user.profile.city_id
    @date = params[:month] ? Date.parse(params[:month]) : Date.today
    @arrival_date = current_user.profile.arrival_date
    @task_deadline = @arrival_date + 3.weeks if @arrival_date

    @calendar_tasks = {
      Date.new(2026, 5, 1) => [
        { name: "Personal Liability Insurance (Privathaftpflicht)", category: "logistics" }
      ],
      Date.new(2026, 5, 12) => [
        { name: "Registration (Anmeldung)", category: "housing" },
        { name: "Open Bank Account", category: "visa" }
      ],
      Date.new(2026, 5, 4) => [
        { name: "Set Up Utilities", category: "Housing" }
      ],
      Date.new(2026, 5, 19) => [
        { name: "Health Insurance Registration", category: "medical" }
      ]
    }

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
    return unless params[:partial]

    if params[:tab] == "completed"
      completed = all_tasks.select { |t| t.completed_by?(current_user) }
      render partial: "kanban", locals: {
        completed_tasks: completed,
        urgent_tasks: [], active_tasks: [], upcoming_tasks: [],
        urgent_count: 0, active_count: 0, upcoming_count: 0
      }
    else
      render partial: "kanban", locals: {
        completed_tasks: nil,
        urgent_tasks: @urgent_tasks,
        active_tasks: @active_tasks,
        upcoming_tasks: @upcoming_tasks,
        urgent_count: @urgent_count,
        active_count: @active_count,
        upcoming_count: @upcoming_count
      }
    end
  end
end
