class OnboardingsController < ApplicationController
  before_action :set_profile
  before_action :set_onboarding_options

  CITY_NAMES = ["Berlin", "Munich", "Hamburg"].freeze

  VISA_OPTIONS = [
    {
      value: "student",
      icon: "bi-mortarboard",
      title: "Student Visa",
      description: "I am enrolled in a university or recognized language course."
    },
    {
      value: "employment",
      icon: "bi-briefcase",
      title: "Work/Visa Employment",
      description: "I have a job offer or I am moving for corporate relocation."
    },
    {
      value: "freelancer",
      icon: "bi-laptop",
      title: "Freelancer/Self-Employed",
      description: "I work remotely or run my own business as a self-employed person."
    },
    {
      value: "eu_citizen",
      icon: "bi-globe-europe-africa",
      title: "EU Citizen / No Visa Needed",
      description: "I hold a passport that allows me to live and work without a visa."
    }
  ].freeze

  HOME_OPTIONS = [
    {
      value: "true",
      icon: "bi-graph-up-arrow",
      title: "Yes, I have accommodation",
      description: "I've already signed a lease or purchased a property and have an address ready for my move."
    },
    {
      value: "false",
      icon: "bi-buildings",
      title: "No, I'm looking for a place",
      description: "I need help finding a rental or area guides for my new city."
    }
  ].freeze

  def show; end

  def update
    if @profile.update(onboarding_params) && @profile.onboardings_complete?
      redirect_to root_path, notice: "Onboarding complete!"
    else
      @profile.errors.add(:base, "Please complete the required onboarding steps.") if @profile.errors.empty?
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.profile || current_user.create_profile
  end

  def set_onboarding_options
    @city_names = CITY_NAMES
    @cities_by_name = City.where(country: "Germany", name: CITY_NAMES).index_by(&:name)
    @visa_options = VISA_OPTIONS
    @home_options = HOME_OPTIONS
  end

  def onboarding_params
    params.require(:profile).permit(:city_id, :arrival_date, :visa_status, :has_home)
  end
end
