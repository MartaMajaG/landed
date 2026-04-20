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

ActiveRecord::Schema[8.1].define(version: 2026_04_20_155526) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chats", force: :cascade do |t|
    t.bigint "checklist_item_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["checklist_item_id"], name: "index_chats_on_checklist_item_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "checklist_items", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "position"
    t.bigint "task_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_checklist_items_on_task_id"
  end

  create_table "cities", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "city_id", null: false
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["city_id"], name: "index_profiles_on_city_id"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "city_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_tasks_on_city_id"
  end

  create_table "user_checklist_items", force: :cascade do |t|
    t.bigint "checklist_item_id", null: false
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["checklist_item_id"], name: "index_user_checklist_items_on_checklist_item_id"
    t.index ["user_id"], name: "index_user_checklist_items_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "chats", "checklist_items"
  add_foreign_key "chats", "users"
  add_foreign_key "checklist_items", "tasks"
  add_foreign_key "messages", "chats"
  add_foreign_key "profiles", "cities"
  add_foreign_key "profiles", "users"
  add_foreign_key "tasks", "cities"
  add_foreign_key "user_checklist_items", "checklist_items"
  add_foreign_key "user_checklist_items", "users"
end
