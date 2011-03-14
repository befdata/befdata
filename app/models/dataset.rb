class Dataset < ActiveRecord::Base

  belongs_to :upload_spreadsheet, :class_name => "Filevalue",
                                  :foreign_key => "upload_spreadsheet_id"

  is_taggable :projecttags

  # tagging
  is_taggable :tags, :languages

  validates_presence_of :title, :abstract, :filename
  validates_uniqueness_of :title, :filename
end
