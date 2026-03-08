class CreateEventEraRestrictions < ActiveRecord::Migration[8.1]
  def change
    create_table :event_era_restrictions do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :era_mul_id
      t.string :era_name

      t.timestamps
    end
  end
end
