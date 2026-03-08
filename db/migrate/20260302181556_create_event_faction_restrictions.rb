class CreateEventFactionRestrictions < ActiveRecord::Migration[8.1]
  def change
    create_table :event_faction_restrictions do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :faction_mul_id
      t.string :faction_name

      t.timestamps
    end
  end
end
