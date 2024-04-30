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

ActiveRecord::Schema[7.1].define(version: 2024_04_30_050650) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "fantasy_managers", force: :cascade do |t|
    t.bigint "fantasy_team_id"
    t.integer "manager_id"
    t.string "nickname"
    t.string "img_url"
    t.index ["fantasy_team_id"], name: "index_fantasy_managers_on_fantasy_team_id"
  end

  create_table "fantasy_teams", force: :cascade do |t|
    t.string "team_key"
    t.string "team_name"
    t.string "team_logo_url"
    t.integer "waiver_priority"
    t.integer "weekly_moves"
    t.bigint "fantasy_manager_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fantasy_manager_id"], name: "index_fantasy_teams_on_fantasy_manager_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "type"
    t.string "full_name"
    t.string "team"
    t.integer "yahoo_id"
    t.jsonb "data", default: {}
    t.string "first_name"
    t.string "last_name"
    t.string "positions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fantasy_team_id"
  end

end
