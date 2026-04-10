class AddAllowedTechBasesToEventSides < ActiveRecord::Migration[8.1]
  def change
    add_column :event_sides, :allowed_tech_bases, :json
  end
end
