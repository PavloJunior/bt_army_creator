class AddSkillToArmyListItems < ActiveRecord::Migration[8.1]
  def change
    add_column :army_list_items, :skill, :integer, null: false, default: 4
  end
end
