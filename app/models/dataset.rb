class Dataset < ActiveRecord::Base

  acts_as_authorization_object :subject_class_name => 'User'
  is_taggable :projecttags
  is_taggable :tags, :languages

  belongs_to :upload_spreadsheet, :class_name => "Filevalue",
                                  :foreign_key => "upload_spreadsheet_id"



  validates_presence_of :title, :abstract, :filename
  validates_uniqueness_of :title, :filename
end
