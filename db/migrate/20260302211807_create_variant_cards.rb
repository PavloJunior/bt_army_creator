class CreateVariantCards < ActiveRecord::Migration[8.1]
  def change
    create_table :variant_cards do |t|
      t.references :variant, null: false, foreign_key: true
      t.integer :skill, null: false, default: 4

      t.timestamps
    end

    add_index :variant_cards, [ :variant_id, :skill ], unique: true
  end
end
