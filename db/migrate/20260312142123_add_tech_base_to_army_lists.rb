class AddTechBaseToArmyLists < ActiveRecord::Migration[8.1]
  def change
    add_column :army_lists, :tech_base, :string, null: false, default: "mixed"
  end
end
