class CreateEventSideFactions < ActiveRecord::Migration[8.1]
  def change
    create_table :event_side_factions do |t|
      t.integer :event_side_id, null: false
      t.integer :faction_mul_id, null: false
      t.string :faction_name, null: false

      t.timestamps
    end

    add_index :event_side_factions, :event_side_id
    add_index :event_side_factions, [ :event_side_id, :faction_mul_id ], unique: true
    add_foreign_key :event_side_factions, :event_sides
  end
end
