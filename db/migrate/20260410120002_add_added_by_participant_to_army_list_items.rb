class AddAddedByParticipantToArmyListItems < ActiveRecord::Migration[8.1]
  def change
    add_column :army_list_items, :added_by_participant_id, :integer
    add_index :army_list_items, :added_by_participant_id
    add_foreign_key :army_list_items,
                    :shared_army_list_participants,
                    column: :added_by_participant_id
  end
end
