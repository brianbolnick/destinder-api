# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171221174615) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "badges_sashes", force: :cascade do |t|
    t.integer "badge_id"
    t.integer "sash_id"
    t.boolean "notified_user", default: false
    t.datetime "created_at"
    t.index ["badge_id", "sash_id"], name: "index_badges_sashes_on_badge_id_and_sash_id"
    t.index ["badge_id"], name: "index_badges_sashes_on_badge_id"
    t.index ["sash_id"], name: "index_badges_sashes_on_sash_id"
  end

  create_table "character_details", force: :cascade do |t|
    t.bigint "character_id"
    t.string "character_type"
    t.string "subclass"
    t.integer "light_level"
    t.string "emblem"
    t.string "emblem_background"
    t.string "last_login"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_character_details_on_character_id"
  end

  create_table "characters", force: :cascade do |t|
    t.string "character_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_characters_on_character_id", unique: true
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "fireteams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_sets", force: :cascade do |t|
    t.bigint "character_id"
    t.bigint "kinetic_weapon"
    t.bigint "energy_weapon"
    t.bigint "power_weapon"
    t.bigint "helmet"
    t.bigint "gauntlets"
    t.bigint "chest_armor"
    t.bigint "leg_armor"
    t.bigint "class_item"
    t.bigint "subclass"
    t.bigint "aura"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_item_sets_on_character_id"
  end

  create_table "items", force: :cascade do |t|
    t.bigint "item_set_id"
    t.string "item_name"
    t.string "item_type"
    t.string "item_icon"
    t.string "item_tier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "item_hash"
    t.bigint "bucket_hash"
    t.index ["item_set_id"], name: "index_items_on_item_set_id"
  end

  create_table "lfg_posts", force: :cascade do |t|
    t.boolean "is_fireteam_post"
    t.text "player_data"
    t.string "fireteam_name"
    t.string "fireteam_data", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "message"
    t.bigint "user_id"
    t.boolean "has_mic"
    t.string "looking_for"
    t.text "game_type"
    t.text "character_data"
    t.string "platform"
    t.string "checkpoint"
    t.index ["user_id", "created_at"], name: "index_lfg_posts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_lfg_posts_on_user_id"
  end

  create_table "merit_actions", force: :cascade do |t|
    t.integer "user_id"
    t.string "action_method"
    t.integer "action_value"
    t.boolean "had_errors", default: false
    t.string "target_model"
    t.integer "target_id"
    t.text "target_data"
    t.boolean "processed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "merit_activity_logs", force: :cascade do |t|
    t.integer "action_id"
    t.string "related_change_type"
    t.integer "related_change_id"
    t.string "description"
    t.datetime "created_at"
  end

  create_table "merit_score_points", force: :cascade do |t|
    t.bigint "score_id"
    t.integer "num_points", default: 0
    t.string "log"
    t.datetime "created_at"
    t.index ["score_id"], name: "index_merit_score_points_on_score_id"
  end

  create_table "merit_scores", force: :cascade do |t|
    t.bigint "sash_id"
    t.string "category", default: "default"
    t.index ["sash_id"], name: "index_merit_scores_on_sash_id"
  end

  create_table "sashes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.string "api_membership_type"
    t.string "api_membership_id"
    t.string "provider"
    t.string "about"
    t.string "profile_picture"
    t.string "locale"
    t.integer "sash_id"
    t.integer "level", default: 0
    t.text "character_data"
  end

  create_table "votes", force: :cascade do |t|
    t.boolean "vote", default: false, null: false
    t.string "voteable_type", null: false
    t.bigint "voteable_id", null: false
    t.string "voter_type"
    t.bigint "voter_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["voteable_id", "voteable_type"], name: "index_votes_on_voteable_id_and_voteable_type"
    t.index ["voteable_type", "voteable_id"], name: "index_votes_on_voteable_type_and_voteable_id"
    t.index ["voter_id", "voter_type", "voteable_id", "voteable_type"], name: "fk_one_vote_per_user_per_entity", unique: true
    t.index ["voter_id", "voter_type"], name: "index_votes_on_voter_id_and_voter_type"
    t.index ["voter_type", "voter_id"], name: "index_votes_on_voter_type_and_voter_id"
  end

  add_foreign_key "character_details", "characters"
  add_foreign_key "characters", "users"
  add_foreign_key "item_sets", "characters"
  add_foreign_key "items", "item_sets"
  add_foreign_key "lfg_posts", "users"
end
