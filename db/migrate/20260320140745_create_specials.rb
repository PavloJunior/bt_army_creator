class CreateSpecials < ActiveRecord::Migration[8.1]
  def change
    create_table :specials do |t|
      t.string :abbreviation, null: false
      t.string :full_name, null: false
      t.text :description

      t.timestamps
    end
    add_index :specials, :abbreviation, unique: true
  end
end
