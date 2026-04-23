class MakeCityIdNullableInProfiles < ActiveRecord::Migration[8.1]
  def change
    change_column_null :profiles, :city_id, true
  end
end
