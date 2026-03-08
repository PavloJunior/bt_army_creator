class CreateMiniatureLocks < ActiveRecord::Migration[8.1]
  def change
    create_table :miniature_locks do |t|
      t.references :miniature, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :army_list, null: false, foreign_key: true

      t.timestamps
    end

    add_index :miniature_locks, [ :miniature_id, :event_id ], unique: true
  end
end
