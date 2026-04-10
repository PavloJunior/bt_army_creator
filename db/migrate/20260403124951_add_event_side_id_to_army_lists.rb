class AddEventSideIdToArmyLists < ActiveRecord::Migration[8.1]
  def change
    add_column :army_lists, :event_side_id, :integer
    add_index :army_lists, :event_side_id
    add_foreign_key :army_lists, :event_sides
  end
end
