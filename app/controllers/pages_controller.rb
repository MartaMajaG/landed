class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def index
    @user = current_user
    @profile = current_user.profile
    @tasks = @profile.tasks
  end

  def home
  end
end
