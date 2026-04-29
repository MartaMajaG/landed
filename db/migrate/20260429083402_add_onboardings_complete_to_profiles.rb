class AddOnboardingsCompleteToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :onboardings_complete, :boolean
  end
end
