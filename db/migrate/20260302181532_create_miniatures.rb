class CreateMiniatures < ActiveRecord::Migration[8.1]
  def change
    create_table :miniatures do |t|
      t.references :chassis, null: false, foreign_key: true
      t.string :label
      t.text :notes

      t.timestamps
    end
  end
end
