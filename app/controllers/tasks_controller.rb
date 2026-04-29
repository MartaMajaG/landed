class TasksController < ApplicationController
  def index
    city_tasks = Task.where(city_id: current_user.profile.city_id)

    if params[:tab] == "completed"
      @tasks = city_tasks.select { |task| task.completed_by?(current_user) }
    else
      @tasks = city_tasks.reject { |task| task.completed_by?(current_user) }
    end
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

    @manually_unlocked_ids = current_user.user_checklist_items
                                         .where(checklist_item_id: item_ids, manually_unlocked: true)
                                         .pluck(:checklist_item_id).to_set

    pillar_tasks        = Task.where(pillar_id: @task.pillar_id, city_id: @task.city_id).order(:id)
    @task_position      = pillar_tasks.index { |t| t.id == @task.id }.to_i + 1
    @pillar_tasks_count = pillar_tasks.count

    if @task.expert_tips.blank?
      begin
        response = RubyLLM.chat(model: "gpt-4o")
          .with_instructions("You are a relocation expert helping expats move to European cities. Be concise and practical.")
          .ask("For someone completing the task '#{@task.name}' when relocating to a new city, give me exactly 2 expert tips. Return ONLY a JSON array like: [{\"title\": \"tip title\", \"body\": \"tip body\"}, {\"title\": \"tip title\", \"body\": \"tip body\"}]")
          .content
        tips = JSON.parse(response)
        @task.update(expert_tips: tips)
      rescue => e
        Rails.logger.error "LLM expert tips error: #{e.message}"
      end
    end
  end
end
