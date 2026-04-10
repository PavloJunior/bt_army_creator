class CreateEventSides < ActiveRecord::Migration[8.1]
  def change
    create_table :event_sides do |t|
      t.integer :event_id, null: false
      t.string :name, null: false
      t.integer :point_cap, null: false
      t.integer :max_players
      t.integer :position, null: false

      t.timestamps
    end

    add_index :event_sides, :event_id
    add_foreign_key :event_sides, :events
  end
end
