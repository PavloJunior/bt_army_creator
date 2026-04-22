class CreateSharedArmyListMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :shared_army_list_messages do |t|
      t.integer :army_list_id, null: false
      t.integer :participant_id
      t.string :sender_name, null: false
      t.text :body, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :shared_army_list_messages, [ :army_list_id, :created_at ]
    add_index :shared_army_list_messages, :participant_id

    add_foreign_key :shared_army_list_messages, :army_lists
    add_foreign_key :shared_army_list_messages,
                    :shared_army_list_participants,
                    column: :participant_id
  end
end
