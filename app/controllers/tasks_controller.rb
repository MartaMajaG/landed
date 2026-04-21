class TasksController < ApplicationController
  before_action :set_task, only: [:show]
  def index
    @tasks = Task.where(city_id: current_user.profile.city_id)
  end

  def show
    @checklist_items = @task.checklist_items.order(:position)
  end

  private

  def set_task
    @task = Task.find_by! (
      id: params[:id],
      city_id: current_user.profile.city_id)
  end
end
