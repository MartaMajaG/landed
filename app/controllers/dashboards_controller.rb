class DashboardsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
  end

  def show
    city_id = current_user.profile.city_id
    @tasks = Task.includes(:checklist_items).where(city_id: city_id)

    @task_cards = @tasks.map do |task|
      # checklist_items = task.checklist_items

      # total = checklist_items.count
      # completed = UserChecklistItem
      #             .where(user: current_user, checklist_item: checklist_items, completed: true)
      #             .count

      # progress = total.zero? ? 0 : (completed.to_f / total * 100).round
    end
  end
end
