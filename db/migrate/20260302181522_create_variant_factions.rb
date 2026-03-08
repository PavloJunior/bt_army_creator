class CreateVariantFactions < ActiveRecord::Migration[8.1]
  def change
    create_table :variant_factions do |t|
      t.references :variant, null: false, foreign_key: true
      t.integer :faction_id, null: false
      t.string :faction_name, null: false

      t.timestamps
    end

    add_index :variant_factions, [ :variant_id, :faction_id ], unique: true
    add_index :variant_factions, :faction_id
  end
end
