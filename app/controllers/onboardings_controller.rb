class OnboardingsController < ApplicationController
  def show
    @profile = current_user.profile || current_user.create_profile
  end

  def update
    @profile = current_user.profile || current_user.build_profile

    if @profile.update(onboarding_params)
      redirect_to root_path, notice: "Onboarding complete!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def onboarding_params
    params.require(:profile).permit(:city_id, :arrival_date)
  end
end
