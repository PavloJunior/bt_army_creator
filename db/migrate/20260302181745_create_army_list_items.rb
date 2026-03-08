class CreateArmyListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :army_list_items do |t|
      t.references :army_list, null: false, foreign_key: true
      t.references :miniature, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true

      t.timestamps
    end

    add_index :army_list_items, [ :army_list_id, :miniature_id ], unique: true
  end
end
