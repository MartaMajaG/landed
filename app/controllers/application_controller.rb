class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :redirect_if_onboardings_incomplete

  def redirect_if_onboardings_incomplete
    return unless user_signed_in?
    return if devise_controller?
    return if request.path.start_with?("/onboarding")

    profile = current_user.profile
    if profile.nil?
      current_user.create_profile!
      return redirect_to onboarding_path
    end

    return if profile.onboardings_complete?

    redirect_to onboarding_path
  end

  # def after_sign_out_path_for(resource_or_scope)
  #   root_path
  # end
end
