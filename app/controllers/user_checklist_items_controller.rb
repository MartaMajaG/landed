# app/controllers/user_checklist_items_controller.rb
class UserChecklistItemsController < ApplicationController
  def update
    # Find the current user's progress row for this checklist item, or build one if it does not exist yet
    @user_checklist_item = current_user.user_checklist_items.find_or_initialize_by(checklist_item_id: params[:id])

    # Toggle the completed status (true becomes false / false becomes true)
    @user_checklist_item.completed = !@user_checklist_item.completed

    if @user_checklist_item.save
      # Return user to the previous page after successful update
      redirect_back fallback_location: root_path, notice: "Task updated successfully."
    else
      # Return user to the previous page if save fails
      redirect_back fallback_location: root_path, alert: "Unable to update task."
    end
  end
end
