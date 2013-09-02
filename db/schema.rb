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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130827011927) do

  create_table "author_paperproposals", :force => true do |t|
    t.integer  "paperproposal_id"
    t.integer  "user_id"
    t.string   "kind"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "author_paperproposals", ["paperproposal_id"], :name => "index_author_paperproposals_on_paperproposal_id"
  add_index "author_paperproposals", ["user_id", "paperproposal_id"], :name => "index_author_paperproposals_on_user_id_and_paperproposal_id"

  create_table "cart_datasets", :force => true do |t|
    t.integer  "cart_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cart_datasets", ["cart_id"], :name => "index_cart_datasets_on_cart_id"
  add_index "cart_datasets", ["dataset_id"], :name => "index_cart_datasets_on_dataset_id"

  create_table "carts", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string   "short"
    t.string   "long"
    t.text     "description"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "datagroup_id"
    t.integer  "user_id"
    t.integer  "status_id"
  end

  add_index "categories", ["datagroup_id"], :name => "index_categories_on_datagroup_id"
  add_index "categories", ["long"], :name => "index_categories_on_long"
  add_index "categories", ["short"], :name => "index_categoricvalues_on_short"
  add_index "categories", ["status_id"], :name => "index_categories_on_status_id"

  create_table "datacolumns", :force => true do |t|
    t.integer  "datagroup_id"
    t.integer  "dataset_id"
    t.string   "columnheader"
    t.integer  "columnnr"
    t.text     "definition"
    t.string   "unit"
    t.text     "comment"
    t.string   "import_data_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "datagroup_approved"
    t.boolean  "finished"
    t.boolean  "datatype_approved"
    t.string   "informationsource"
    t.string   "instrumentation"
  end

  add_index "datacolumns", ["datagroup_id"], :name => "index_datacolumns_on_datagroup_id"
  add_index "datacolumns", ["dataset_id"], :name => "index_datacolumns_on_dataset_id"

  create_table "datafiles", :force => true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dataset_id"
  end

  add_index "datafiles", ["dataset_id"], :name => "index_datafiles_on_dataset_id"

  create_table "datagroups", :force => true do |t|
    t.string   "informationsource"
    t.string   "methodvaluetype"
    t.string   "title"
    t.text     "description"
    t.string   "instrumentation"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "type_id"
    t.integer  "datacolumns_count", :default => 0
  end

  add_index "datagroups", ["title"], :name => "index_datagroups_on_title"
  add_index "datagroups", ["type_id"], :name => "index_datagroups_on_type_id"

  create_table "dataset_downloads", :force => true do |t|
    t.integer  "user_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dataset_downloads", ["user_id", "dataset_id"], :name => "index_dataset_downloads_on_user_id_and_dataset_id"

  create_table "dataset_edits", :force => true do |t|
    t.integer  "dataset_id"
    t.text     "description"
    t.boolean  "submitted",   :default => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "dataset_edits", ["dataset_id"], :name => "index_dataset_edits_on_dataset_id"

  create_table "dataset_paperproposals", :force => true do |t|
    t.string   "aspect"
    t.integer  "paperproposal_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dataset_paperproposals", ["dataset_id", "paperproposal_id"], :name => "index_dataset_paperproposals_on_dataset_id_and_paperproposal_id"

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
    t.integer  "dataset_downloads_count",            :default => 0
    t.datetime "datemin"
    t.datetime "datemax"
    t.text     "published"
    t.boolean  "visible_for_public",                 :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "student_file",                       :default => false
    t.string   "import_status"
    t.datetime "download_generated_at"
    t.string   "download_generation_status"
    t.string   "generated_spreadsheet_file_name"
    t.string   "generated_spreadsheet_content_type"
    t.integer  "generated_spreadsheet_file_size"
    t.datetime "generated_spreadsheet_updated_at"
    t.integer  "access_code",                        :default => 0
  end

  add_index "datasets", ["filename"], :name => "index_datasets_on_filename"

  create_table "datasets_projects", :id => false, :force => true do |t|
    t.integer  "dataset_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "datasets_projects", ["dataset_id", "project_id"], :name => "index_dataset_projects_on_dataset_id_and_project_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "freeformats", :force => true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "freeformattable_id"
    t.string   "freeformattable_type"
    t.boolean  "is_essential",         :default => false
    t.string   "uri"
  end

  add_index "freeformats", ["freeformattable_type", "freeformattable_id"], :name => "idx_freeformats_type_id"

  create_table "import_categories", :force => true do |t|
    t.integer  "datacolumn_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short"
    t.string   "long"
    t.text     "description"
  end

  add_index "import_categories", ["datacolumn_id"], :name => "index_import_categories_on_datacolumn_id"
  add_index "import_categories", ["long"], :name => "index_import_categories_on_long"
  add_index "import_categories", ["short"], :name => "index_import_categories_on_short"

  create_table "notifications", :force => true do |t|
    t.integer  "user_id"
    t.text     "subject"
    t.text     "message"
    t.boolean  "read",       :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "paperproposal_votes", :force => true do |t|
    t.integer  "paperproposal_id"
    t.integer  "user_id"
    t.string   "comment"
    t.string   "vote",               :default => "none"
    t.boolean  "project_board_vote"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "paperproposal_votes", ["paperproposal_id"], :name => "index_paperproposal_votes_on_paperproposal_id"
  add_index "paperproposal_votes", ["user_id"], :name => "index_paperproposal_votes_on_user_id"

  create_table "paperproposals", :force => true do |t|
    t.integer  "author_id"
    t.text     "envisaged_journal"
    t.string   "title"
    t.text     "rationale"
    t.date     "envisaged_date"
    t.string   "state"
    t.date     "expiry_date"
    t.string   "board_state",       :default => "prep"
    t.string   "external_data"
    t.boolean  "lock",              :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "initial_title"
    t.text     "comment"
    t.integer  "project_id"
  end

  add_index "paperproposals", ["author_id"], :name => "index_paperproposals_on_author_id"
  add_index "paperproposals", ["project_id"], :name => "index_paperproposals_on_project_id"

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
    t.string   "authorizable_type", :limit => 25
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["authorizable_type", "authorizable_id"], :name => "index_roles_on_authorizable_type_and_authorizable_id"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "roles_users", ["user_id", "role_id"], :name => "index_roles_users_on_user_id_and_role_id"

  create_table "sheetcells", :force => true do |t|
    t.integer  "datacolumn_id"
    t.string   "import_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "category_id"
    t.string   "accepted_value"
    t.integer  "datatype_id"
    t.integer  "status_id"
    t.integer  "row_number"
  end

  add_index "sheetcells", ["category_id"], :name => "index_sheetcells_on_category_id"
  add_index "sheetcells", ["datacolumn_id"], :name => "index_sheetcells_on_datacolumn_id"
  add_index "sheetcells", ["row_number"], :name => "index_sheetcells_on_row_number"
  add_index "sheetcells", ["status_id", "datacolumn_id"], :name => "index_sheetcells_on_status_id_and_datacolumn_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                                  :null => false
    t.string   "email",                                  :null => false
    t.string   "crypted_password",                       :null => false
    t.string   "password_salt",                          :null => false
    t.string   "persistence_token",                      :null => false
    t.string   "single_access_token",                    :null => false
    t.string   "perishable_token",                       :null => false
    t.integer  "login_count",         :default => 0,     :null => false
    t.integer  "failed_login_count",  :default => 0,     :null => false
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
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.boolean  "receive_emails",      :default => false
  end

end
