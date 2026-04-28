class PillarsController < ApplicationController
  before_action :set_pillar

  def show
    # All Main Tasks belonging to this Pillar, for the current user's city.
    # Ordered by urgency so high-priority tasks appear first.
    @tasks = @pillar.tasks
                    .where(city_id: current_user.profile.city_id)
                    .order(Arel.sql("CASE urgency WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END"))

    # Pre-load Subtask completion state for each Task in one query (avoids N+1).
    checklist_item_ids = @tasks.flat_map { |t| t.checklist_items.pluck(:id) }
    @user_progress = current_user.user_checklist_items
                                 .where(checklist_item_id: checklist_item_ids)
                                 .index_by(&:checklist_item_id)
  end

  private

  def set_pillar
    # Scope to the user's city so users cannot access another city's pillars.
    @pillar = Pillar.find_by!(
      id:      params[:id],
      city_id: current_user.profile.city_id
    )
  end
end
