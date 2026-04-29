class TasksController < ApplicationController
  def index
    @tasks = Task.where(city_id: current_user.profile.city_id)
  end

  def show
    @task = Task.includes(:pillar).find_by!(
      id: params[:id],
      city_id: current_user.profile.city_id
    )

    @checklist_items = @task.checklist_items.order(:position)
    item_ids         = @checklist_items.pluck(:id)

    @user_checklist_items = current_user.user_checklist_items
                                        .where(checklist_item_id: item_ids)
                                        .index_by(&:checklist_item_id)

    # IDs of steps the user has manually unlocked (overrides soft-lock)
    @manually_unlocked_ids = current_user.user_checklist_items
                                         .where(checklist_item_id: item_ids, manually_unlocked: true)
                                         .pluck(:checklist_item_id).to_set

    # Breadcrumb: Task X of Y within this pillar
    pillar_tasks        = Task.where(pillar_id: @task.pillar_id, city_id: @task.city_id).order(:id)
    @task_position      = pillar_tasks.index { |t| t.id == @task.id }.to_i + 1
    @pillar_tasks_count = pillar_tasks.count
  end
end
