class CreateArmyLists < ActiveRecord::Migration[8.1]
  def change
    create_table :army_lists do |t|
      t.references :event, null: false, foreign_key: true
      t.string :player_name, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :submitted_at

      t.timestamps
    end
  end
end
