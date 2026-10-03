class OnboardingsController < ApplicationController
  before_action :set_profile
  before_action :set_onboarding_options

  CITY_NAMES = ["Berlin", "Munich", "Hamburg"].freeze

  CITY_DETAILS = {
    "Berlin"  => { icon: "building", description: "Bürgeramt and LEA. Appointments go fast." },
    "Munich"  => { icon: "landmark", description: "KVR for registration and permits." },
    "Hamburg" => { icon: "anchor",   description: "Kundenzentrum in every district." }
  }.freeze

  VISA_OPTIONS = [
    { value: "employment", icon: "briefcase", title: "Job offer",          description: "I'm employed by a company in Germany or relocating with my employer." },
    { value: "freelancer", icon: "laptop",    title: "Freelancer",         description: "I'm self-employed or work remotely for clients." },
    { value: "student",    icon: "grad",      title: "Student",            description: "I'm enrolled at a university or a recognised language school." },
    { value: "eu_citizen", icon: "globe",     title: "EU citizen",         description: "I have an EU, EEA or Swiss passport, so I don't need a visa." }
  ].freeze

  HOME_OPTIONS = [
    { value: "true",  icon: "key",    title: "Yes, I have a place",    description: "I've signed a lease, so I have an address to register." },
    { value: "false", icon: "search", title: "Not yet, I'm looking",   description: "I still need to find a flat in my new city." }
  ].freeze

  def show; end

  def update
    if @profile.update(onboarding_params)
      @profile.update(onboardings_complete: true)
      redirect_to dashboard_path, notice: "Onboarding complete!"
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
    @city_details = CITY_DETAILS
    @visa_options = VISA_OPTIONS
    @home_options = HOME_OPTIONS
    @plan_tasks = plan_tasks_for(@cities_by_name.values)
  end

  # Real tasks for each onboarding city, used for the "your plan is ready" preview
  # at the end of the flow. Due dates are worked out client-side from the arrival
  # date the user picks, using the same urgency rule as Task.assign_due_dates.
  def plan_tasks_for(cities)
    Task.where(city: cities).includes(:pillar).map do |task|
      {
        city_id: task.city_id,
        name: task.name,
        urgency: task.urgency,
        pillar_slug: task.pillar&.slug,
        pillar_name: task.pillar&.name,
        why: helpers.first_sentence(task.why_it_matters.presence || task.description, max_length: 110)
      }
    end
  end

  def onboarding_params
    params.require(:profile).permit(:city_id, :arrival_date, :visa_status, :has_home)
  end
end
