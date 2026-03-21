# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_21_161445) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "army_list_factions", force: :cascade do |t|
    t.integer "army_list_id", null: false
    t.datetime "created_at", null: false
    t.integer "faction_mul_id", null: false
    t.datetime "updated_at", null: false
    t.index ["army_list_id", "faction_mul_id"], name: "index_army_list_factions_on_army_list_id_and_faction_mul_id", unique: true
    t.index ["army_list_id"], name: "index_army_list_factions_on_army_list_id"
  end

  create_table "army_list_items", force: :cascade do |t|
    t.integer "army_list_id", null: false
    t.datetime "created_at", null: false
    t.integer "miniature_id", null: false
    t.integer "skill", default: 4, null: false
    t.datetime "updated_at", null: false
    t.integer "variant_id", null: false
    t.index ["army_list_id", "miniature_id"], name: "index_army_list_items_on_army_list_id_and_miniature_id", unique: true
    t.index ["army_list_id"], name: "index_army_list_items_on_army_list_id"
    t.index ["miniature_id"], name: "index_army_list_items_on_miniature_id"
    t.index ["variant_id"], name: "index_army_list_items_on_variant_id"
  end

  create_table "army_lists", force: :cascade do |t|
    t.integer "bonus_points", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.string "player_name", null: false
    t.string "status", default: "draft", null: false
    t.datetime "submitted_at"
    t.string "tech_base", default: "mixed", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_army_lists_on_event_id"
  end

  create_table "chassis", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "image_url"
    t.string "mini_group_id"
    t.datetime "mul_synced_at"
    t.string "name", null: false
    t.integer "tonnage"
    t.string "unit_type"
    t.datetime "updated_at", null: false
    t.index ["mini_group_id"], name: "index_chassis_on_mini_group_id"
    t.index ["name"], name: "index_chassis_on_name", unique: true
  end

  create_table "eras", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "end_year"
    t.integer "mul_id", null: false
    t.string "name", null: false
    t.integer "sort_order"
    t.integer "start_year"
    t.datetime "updated_at", null: false
    t.index ["mul_id"], name: "index_eras_on_mul_id", unique: true
  end

  create_table "event_era_restrictions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "era_mul_id"
    t.string "era_name"
    t.integer "event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_era_restrictions_on_event_id"
  end

  create_table "event_faction_restrictions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.integer "faction_mul_id"
    t.string "faction_name"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_faction_restrictions_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "game_system", null: false
    t.string "name", null: false
    t.text "notes"
    t.integer "point_cap", null: false
    t.string "status", default: "upcoming", null: false
    t.datetime "updated_at", null: false
  end

  create_table "factions", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "mul_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["mul_id"], name: "index_factions_on_mul_id", unique: true
  end

  create_table "miniature_locks", force: :cascade do |t|
    t.integer "army_list_id", null: false
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.integer "miniature_id", null: false
    t.datetime "updated_at", null: false
    t.index ["army_list_id"], name: "index_miniature_locks_on_army_list_id"
    t.index ["event_id"], name: "index_miniature_locks_on_event_id"
    t.index ["miniature_id", "event_id"], name: "index_miniature_locks_on_miniature_id_and_event_id", unique: true
    t.index ["miniature_id"], name: "index_miniature_locks_on_miniature_id"
  end

  create_table "miniatures", force: :cascade do |t|
    t.integer "chassis_id", null: false
    t.datetime "created_at", null: false
    t.string "label"
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["chassis_id"], name: "index_miniatures_on_chassis_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "specials", force: :cascade do |t|
    t.string "abbreviation", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "full_name", null: false
    t.datetime "updated_at", null: false
    t.index ["abbreviation"], name: "index_specials_on_abbreviation", unique: true
  end

  create_table "sync_attempts", force: :cascade do |t|
    t.integer "cards_synced", default: 0
    t.integer "cards_total", default: 0
    t.integer "chassis_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.json "error_messages", default: []
    t.integer "factions_synced", default: 0
    t.integer "factions_total", default: 0
    t.datetime "started_at"
    t.string "status", default: "running", null: false
    t.datetime "updated_at", null: false
    t.integer "variants_count", default: 0
    t.index ["chassis_id"], name: "index_sync_attempts_on_chassis_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "variant_cards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "skill", default: 4, null: false
    t.datetime "updated_at", null: false
    t.integer "variant_id", null: false
    t.index ["variant_id", "skill"], name: "index_variant_cards_on_variant_id_and_skill", unique: true
    t.index ["variant_id"], name: "index_variant_cards_on_variant_id"
  end

  create_table "variant_factions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "faction_id", null: false
    t.string "faction_name", null: false
    t.datetime "updated_at", null: false
    t.integer "variant_id", null: false
    t.index ["faction_id"], name: "index_variant_factions_on_faction_id"
    t.index ["variant_id", "faction_id"], name: "index_variant_factions_on_variant_id_and_faction_id", unique: true
    t.index ["variant_id"], name: "index_variant_factions_on_variant_id"
  end

  create_table "variants", force: :cascade do |t|
    t.integer "battle_value"
    t.string "bf_abilities"
    t.integer "bf_armor"
    t.integer "bf_damage_long"
    t.integer "bf_damage_medium"
    t.integer "bf_damage_short"
    t.string "bf_move"
    t.integer "bf_overheat"
    t.integer "bf_size"
    t.integer "bf_structure"
    t.integer "bf_threshold"
    t.integer "chassis_id", null: false
    t.datetime "created_at", null: false
    t.string "date_introduced"
    t.integer "era_id"
    t.string "era_name"
    t.string "image_url"
    t.integer "mul_id", null: false
    t.string "name", null: false
    t.integer "point_value"
    t.json "raw_mul_data"
    t.string "role"
    t.string "rules_level"
    t.string "technology"
    t.integer "tonnage"
    t.string "unit_type"
    t.datetime "updated_at", null: false
    t.string "variant_code"
    t.index ["chassis_id"], name: "index_variants_on_chassis_id"
    t.index ["date_introduced"], name: "index_variants_on_date_introduced"
    t.index ["era_id"], name: "index_variants_on_era_id"
    t.index ["mul_id"], name: "index_variants_on_mul_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "army_list_factions", "army_lists"
  add_foreign_key "army_list_items", "army_lists"
  add_foreign_key "army_list_items", "miniatures"
  add_foreign_key "army_list_items", "variants"
  add_foreign_key "army_lists", "events"
  add_foreign_key "event_era_restrictions", "events"
  add_foreign_key "event_faction_restrictions", "events"
  add_foreign_key "miniature_locks", "army_lists"
  add_foreign_key "miniature_locks", "events"
  add_foreign_key "miniature_locks", "miniatures"
  add_foreign_key "miniatures", "chassis"
  add_foreign_key "sessions", "users"
  add_foreign_key "sync_attempts", "chassis"
  add_foreign_key "variant_cards", "variants"
  add_foreign_key "variant_factions", "variants"
  add_foreign_key "variants", "chassis"
end
