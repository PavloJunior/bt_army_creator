class AddThemedToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :themed, :boolean, default: false, null: false
  end
end
