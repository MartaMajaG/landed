class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :redirect_if_onboarding_incomplete

  def redirect_if_onboarding_incomplete
    return unless user_signed_in?

    profile = current_user.profile
    if profile.nil?
      current_user.create_profile!
      return redirect_to onboarding_path
    end

    return unless profile.city_id.blank? || profile.arrival_date.blank?

    redirect_to onboarding_path unless request.path == onboarding_path
  end
end
