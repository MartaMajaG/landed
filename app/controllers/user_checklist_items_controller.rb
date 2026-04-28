class UserChecklistItemsController < ApplicationController
  def update
    @user_checklist_item = current_user.user_checklist_items.find_or_initialize_by(checklist_item_id: params[:id])
    @user_checklist_item.completed = !@user_checklist_item.completed

    if @user_checklist_item.save
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, notice: "Task updated successfully." }
        format.json { render json: { success: true, completed: @user_checklist_item.completed } }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "Unable to update task." }
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end
end
