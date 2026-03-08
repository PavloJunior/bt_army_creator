class CreateEras < ActiveRecord::Migration[8.1]
  def change
    create_table :eras do |t|
      t.integer :mul_id, null: false
      t.string :name, null: false
      t.integer :start_year
      t.integer :end_year
      t.integer :sort_order

      t.timestamps
    end

    add_index :eras, :mul_id, unique: true
  end
end
