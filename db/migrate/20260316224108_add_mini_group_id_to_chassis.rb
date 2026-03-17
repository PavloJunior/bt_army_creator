class AddMiniGroupIdToChassis < ActiveRecord::Migration[8.1]
  def change
    add_column :chassis, :mini_group_id, :string
    add_index :chassis, :mini_group_id
  end
end
