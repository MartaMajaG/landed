class DashboardsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @user = current_user
    @profile = current_user.profile
    @tasks = @profile.tasks
    # @tasks = @profile.tasks.order(
    #   Arel.sql("CASE urgency
    #               WHEN 'high' THEN 1
    #               WHEN 'medium' THEN 2
    #               WHEN 'low' THEN 3
    #             END")
    # )
  end
end
