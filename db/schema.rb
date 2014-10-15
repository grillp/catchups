# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20141015021227) do

  create_table "catchup_rotations", force: true do |t|
    t.string   "name"
    t.integer  "frequency_in_days"
    t.integer  "catchup_length_in_minutes"
    t.integer  "members_per_catchup"
    t.string   "location"
    t.date     "latest_rotation_started_at"
    t.date     "latest_rotation_ended_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rotation_members", force: true do |t|
    t.string   "name"
    t.string   "nickname"
    t.string   "title"
    t.string   "email"
    t.integer  "catchup_rotation_id"
    t.datetime "latest_catchup_at"
    t.string   "latest_catchup_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rotation_members", ["catchup_rotation_id"], name: "index_rotation_members_on_catchup_rotation_id"

end
