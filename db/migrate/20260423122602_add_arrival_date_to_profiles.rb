class AddArrivalDateToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :arrival_date, :date
  end
end
