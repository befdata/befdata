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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110315095614) do

  create_table "categoricvalues", :force => true do |t|
    t.string   "short"
    t.string   "long"
    t.text     "description"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "datacolumns", :force => true do |t|
    t.integer  "datagroup_id"
    t.integer  "dataset_id"
    t.string   "columnheader"
    t.integer  "columnnr"
    t.text     "definition"
    t.string   "unit"
    t.string   "missingcode"
    t.text     "comment"
    t.string   "import_data_type"
    t.string   "category_longshort"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "datagroups", :force => true do |t|
    t.string   "informationsource"
    t.string   "methodvaluetype"
    t.string   "title"
    t.text     "description"
    t.string   "instrumentation"
    t.float    "timelatency"
    t.string   "timelatencyunit"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "datasets", :force => true do |t|
    t.string   "title"
    t.text     "abstract"
    t.text     "usagerights"
    t.text     "spatialextent"
    t.text     "temporalextent"
    t.text     "taxonomicextent"
    t.text     "design"
    t.text     "circumstances"
    t.datetime "submission_at"
    t.string   "filename"
    t.text     "comment"
    t.text     "dataanalysis"
    t.boolean  "finished"
    t.integer  "downloads",             :default => 0
    t.datetime "datemin"
    t.datetime "datemax"
    t.text     "published"
    t.boolean  "visible_for_public",    :default => true
    t.integer  "upload_spreadsheet_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "datetimevalues", :force => true do |t|
    t.datetime "date"
    t.integer  "year"
    t.integer  "month"
    t.integer  "day"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "filevalues", :force => true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "data_proposal_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "import_categoricvalues", :force => true do |t|
    t.integer  "datacolumn_id"
    t.string   "raw_data_value"
    t.integer  "categoricvalue_id"
    t.boolean  "approved"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "numericvalues", :force => true do |t|
    t.float    "number"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "observations", :force => true do |t|
    t.text     "comment"
    t.integer  "rownr"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "observations_sheetcells", :force => true do |t|
    t.integer  "observation_id"
    t.integer  "sheetcell_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "shortname"
    t.string   "name"
    t.text     "description"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sheetcells", :force => true do |t|
    t.integer  "datacolumn_id"
    t.integer  "value_id"
    t.string   "value_type"
    t.integer  "rownr"
    t.text     "comment"
    t.integer  "observation_id"
    t.string   "import_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer "tag_id"
    t.string  "taggable_type", :default => ""
    t.integer "taggable_id"
  end

  create_table "tags", :force => true do |t|
    t.string "name", :default => ""
    t.string "kind", :default => ""
  end

  create_table "textvalues", :force => true do |t|
    t.string   "text"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                              :null => false
    t.string   "email",                              :null => false
    t.string   "crypted_password",                   :null => false
    t.string   "password_salt",                      :null => false
    t.string   "persistence_token",                  :null => false
    t.string   "single_access_token",                :null => false
    t.string   "perishable_token",                   :null => false
    t.integer  "login_count",         :default => 0, :null => false
    t.integer  "failed_login_count",  :default => 0, :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.string   "firstname"
    t.string   "middlenames"
    t.string   "lastname"
    t.string   "salutation"
    t.text     "comment"
    t.string   "url"
    t.string   "institution_name"
    t.text     "affiliation"
    t.string   "institution_url"
    t.string   "institution_phone"
    t.string   "institution_fax"
    t.string   "street"
    t.string   "city"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
