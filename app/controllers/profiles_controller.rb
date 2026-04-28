class ProfilesController < ApplicationController
  def show
    @profile = current_user.profile || current_user.create_profile
  end

  def edit
    @profile = current_user.profile || current_user.create_profile
    @cities = City.where(country: "Germany").order(:name)
  end

  def update
    @profile = current_user.profile || current_user.create_profile
    @cities = City.where(country: "Germany").order(:name)
    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Profile updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:first_name, :last_name, :city_id, :arrival_date, :visa_status, :has_home)
  end
end
