class UserChecklistItemsController < ApplicationController
  def update
    # Find the specific checklist item for the user
    @user_checklist_item = UserChecklistItem.find(params[:id])

    # Toggle the completed status (inverts the current boolean value)
    @user_checklist_item.completed = !@user_checklist_item.completed

    if @user_checklist_item.save
      # Redirect back to the page where the request originated
      redirect_back fallback_location: root_path, notice: "Task updated successfully."
    else
      # Fallback in case of save errors
      redirect_back fallback_location: root_path, alert: "Unable to update task."
    end
  end
end
