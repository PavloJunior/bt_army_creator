class CreateChassis < ActiveRecord::Migration[8.1]
  def change
    create_table :chassis do |t|
      t.string :name, null: false
      t.string :unit_type
      t.integer :tonnage
      t.string :image_url
      t.datetime :mul_synced_at

      t.timestamps
    end

    add_index :chassis, :name, unique: true
  end
end
