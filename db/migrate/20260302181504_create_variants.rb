class CreateVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :variants do |t|
      t.references :chassis, null: false, foreign_key: true
      t.integer :mul_id, null: false
      t.string :name, null: false
      t.string :variant_code
      t.integer :battle_value
      t.integer :point_value
      t.integer :tonnage
      t.string :unit_type
      t.string :technology
      t.string :role
      t.string :date_introduced
      t.integer :era_id
      t.string :era_name
      t.string :rules_level
      t.string :image_url
      t.string :bf_move
      t.integer :bf_armor
      t.integer :bf_structure
      t.integer :bf_threshold
      t.integer :bf_damage_short
      t.integer :bf_damage_medium
      t.integer :bf_damage_long
      t.integer :bf_size
      t.integer :bf_overheat
      t.string :bf_abilities
      t.json :raw_mul_data

      t.timestamps
    end

    add_index :variants, :mul_id, unique: true
    add_index :variants, :era_id
    add_index :variants, :date_introduced
  end
end
