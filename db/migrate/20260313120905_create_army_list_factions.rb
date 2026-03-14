class CreateArmyListFactions < ActiveRecord::Migration[8.1]
  def change
    create_table :army_list_factions do |t|
      t.references :army_list, null: false, foreign_key: true
      t.integer :faction_mul_id, null: false

      t.timestamps
    end

    add_index :army_list_factions, [ :army_list_id, :faction_mul_id ], unique: true
  end
end
