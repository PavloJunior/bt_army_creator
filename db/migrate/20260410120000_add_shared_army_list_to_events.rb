class AddSharedArmyListToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :shared_army_list, :boolean, default: false, null: false
  end
end
