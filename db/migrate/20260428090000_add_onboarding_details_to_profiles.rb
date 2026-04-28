class AddOnboardingDetailsToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :visa_status, :string
    add_column :profiles, :has_home, :boolean
  end
end
