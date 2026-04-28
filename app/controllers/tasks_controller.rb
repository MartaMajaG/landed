class TasksController < ApplicationController
  before_action :set_task, only: [:show]
  def index
    @tasks = Task.where(city_id: current_user.profile.city_id)
  end

  def show
    @checklist_items = @task.checklist_items.order(:position)
    item_ids         = @checklist_items.pluck(:id)

    @user_checklist_items = current_user.user_checklist_items
                                        .where(checklist_item_id: item_ids)
                                        .index_by(&:checklist_item_id)

    # IDs of steps the user has manually unlocked (overrides soft-lock)
    @manually_unlocked_ids = current_user.user_checklist_items
                                         .where(checklist_item_id: item_ids, manually_unlocked: true)
                                         .pluck(:checklist_item_id).to_set
  end

  private

  def set_task
    @task = Task.find_by!(
      id: params[:id],
      city_id: current_user.profile.city_id
    )
  end
end
