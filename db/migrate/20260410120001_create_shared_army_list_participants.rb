class CreateSharedArmyListParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :shared_army_list_participants do |t|
      t.integer :army_list_id, null: false
      t.string :display_name, null: false
      t.string :token, null: false
      t.datetime :accepted_at
      t.datetime :left_at

      t.timestamps
    end

    add_index :shared_army_list_participants, :army_list_id
    add_index :shared_army_list_participants, :token, unique: true
    add_index :shared_army_list_participants,
              "army_list_id, LOWER(display_name)",
              unique: true,
              where: "left_at IS NULL",
              name: "idx_shared_participants_unique_active_name"

    add_foreign_key :shared_army_list_participants, :army_lists
  end
end
