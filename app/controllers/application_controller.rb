class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :redirect_if_onboardings_incomplete

  def redirect_if_onboardings_incomplete
    return unless user_signed_in?

    profile = current_user.profile
    if profile.nil?
      current_user.create_profile!
      return redirect_to onboarding_path
    end

    return unless profile.city_id.blank? || profile.arrival_date.blank?

    redirect_to onboarding_path unless request.path == onboarding_path
  end

  # def after_sign_out_path_for(resource_or_scope)
  #   root_path
  # end
end
