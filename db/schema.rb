# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110222125147) do

  create_table "author_data_requests", :force => true do |t|
    t.integer  "data_request_id"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "kind"
  end

  create_table "cart_contexts", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.integer  "cart_id"
    t.integer  "context_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cart_data_columns", :force => true do |t|
    t.integer  "cart_id"
    t.integer  "measurements_methodstep_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "carts", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categoricvalue_trigrams", :force => true do |t|
    t.integer "categoricvalue_id"
    t.string  "token",             :null => false
  end

  create_table "categoricvalues", :force => true do |t|
    t.string   "short"
    t.string   "long"
    t.text     "description"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "context_freepeople", :force => true do |t|
    t.integer  "person_id"
    t.integer  "context_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "context_freeprojects", :force => true do |t|
    t.integer  "project_id"
    t.integer  "context_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "context_person_roles", :force => true do |t|
    t.integer  "context_id"
    t.integer  "person_role_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contexts", :force => true do |t|
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "dataanalysis"
    t.boolean  "finished"
    t.integer  "downloads",             :default => 0
    t.datetime "datemin"
    t.datetime "datemax"
    t.text     "published"
    t.boolean  "visible_for_public",    :default => true
    t.integer  "upload_spreadsheet_id"
  end

  create_table "data_group_data_requests", :force => true do |t|
    t.string   "aspect"
    t.integer  "data_request_id"
    t.integer  "measurements_methodstep_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_request_contexts", :id => false, :force => true do |t|
    t.integer  "id",              :null => false
    t.string   "aspect"
    t.integer  "data_request_id"
    t.integer  "context_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_request_votes", :force => true do |t|
    t.integer  "data_request_id"
    t.integer  "person_id"
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "vote",               :default => "none"
    t.boolean  "project_board_vote"
  end

  create_table "data_requests", :force => true do |t|
    t.integer  "author_id"
    t.string   "envisaged_journal"
    t.string   "title"
    t.string   "rationale"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "corresponding_id"
    t.date     "envisaged_date"
    t.string   "state"
    t.date     "expiry_date"
    t.string   "board_state",       :default => "prep"
    t.integer  "senior_author_id"
    t.string   "external_data"
    t.boolean  "lock",              :default => false
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "data_request_id"
  end

  create_table "import_categories", :force => true do |t|
    t.integer  "measurements_methodstep_id"
    t.string   "raw_data_value"
    t.integer  "categoricvalue_id"
    t.boolean  "approved"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "institutions", :force => true do |t|
    t.string   "name"
    t.text     "affiliation"
    t.string   "url"
    t.string   "email"
    t.string   "phone"
    t.string   "fax"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "street"
    t.string   "city"
    t.string   "country"
  end

  create_table "locations", :force => true do |t|
    t.string   "shortname"
    t.string   "name"
    t.text     "description"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "measmeths_personroles", :force => true do |t|
    t.integer  "measurements_methodstep_id"
    t.integer  "person_role_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "measurements", :force => true do |t|
    t.integer  "measurements_methodstep_id"
    t.integer  "value_id"
    t.string   "value_type"
    t.integer  "rownr"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "observation_id"
    t.string   "import_value"
  end

  add_index "measurements", ["value_id", "value_type"], :name => "index_measurements_on_value_id_and_value_type"
  add_index "measurements", ["value_type"], :name => "index_measurements_on_value_type"

  create_table "measurements_methodsteps", :force => true do |t|
    t.integer  "methodstep_id"
    t.integer  "context_id"
    t.string   "columnheader"
    t.integer  "columnnr"
    t.text     "definition"
    t.string   "unit"
    t.string   "missingcode"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "import_data_type"
    t.string   "category_longshort"
  end

  create_table "methodsteps", :force => true do |t|
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

  create_table "numericvalues", :force => true do |t|
    t.float    "number"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "observations", :force => true do |t|
    t.integer  "year"
    t.integer  "month"
    t.integer  "day"
    t.datetime "date"
    t.integer  "location_id"
    t.integer  "entity_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rownr"
  end

  create_table "observations_measurements", :force => true do |t|
    t.integer  "observation_id"
    t.integer  "measurement_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people", :force => true do |t|
    t.string   "firstname"
    t.string   "middlenames"
    t.string   "lastname"
    t.string   "salutation"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "login",                     :limit => 40
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
  end

  create_table "person_addresses", :force => true do |t|
    t.integer  "person_id"
    t.string   "person_txtid"
    t.string   "url"
    t.string   "phone"
    t.string   "email"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "person_roles", :force => true do |t|
    t.integer  "person_id"
    t.string   "person_txtid"
    t.integer  "project_id"
    t.integer  "institution_id"
    t.string   "role_old"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "project_shortname"
    t.integer  "role_id"
  end

  create_table "person_trigrams", :force => true do |t|
    t.integer "person_id"
    t.string  "token",     :null => false
  end

  create_table "projects", :force => true do |t|
    t.string   "shortname"
    t.string   "name"
    t.text     "description"
    t.text     "funding"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "regioncoords", :force => true do |t|
    t.integer  "location_id"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "rank"
    t.boolean  "reference"
    t.float    "xdim"
    t.float    "xangle"
    t.float    "ydim"
    t.float    "yangle"
    t.float    "area"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
  end

  create_table "roles_people", :id => false, :force => true do |t|
    t.integer  "person_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer "tag_id"
    t.string  "taggable_type", :default => ""
    t.integer "taggable_id"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name", :default => ""
    t.string "kind", :default => ""
  end

  add_index "tags", ["name", "kind"], :name => "index_tags_on_name_and_kind"

  create_table "textvalues", :force => true do |t|
    t.string   "text"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
