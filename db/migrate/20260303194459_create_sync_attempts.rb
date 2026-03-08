class CreateSyncAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_attempts do |t|
      t.references :chassis, null: false, foreign_key: true
      t.string :status, null: false, default: "running"
      t.integer :variants_count, default: 0
      t.integer :factions_total, default: 0
      t.integer :factions_synced, default: 0
      t.integer :cards_total, default: 0
      t.integer :cards_synced, default: 0
      t.json :error_messages, default: []
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
