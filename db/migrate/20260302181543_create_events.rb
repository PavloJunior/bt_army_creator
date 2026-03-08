class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.date :date, null: false
      t.string :game_system, null: false
      t.integer :point_cap, null: false
      t.string :status, null: false, default: "upcoming"
      t.text :notes

      t.timestamps
    end
  end
end
