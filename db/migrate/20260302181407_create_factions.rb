class CreateFactions < ActiveRecord::Migration[8.1]
  def change
    create_table :factions do |t|
      t.integer :mul_id, null: false
      t.string :name, null: false
      t.string :category

      t.timestamps
    end

    add_index :factions, :mul_id, unique: true
  end
end
