class Dataset < ActiveRecord::Base

  acts_as_authorization_object :subject_class_name => 'User'
  is_taggable :projecttags
  is_taggable :tags, :languages

  belongs_to :upload_spreadsheet, :class_name => "Filevalue",
                                  :foreign_key => "upload_spreadsheet_id"
  has_many :datacolumns, :dependent => :destroy, :order => "columnnr"
  has_many :sheetcells, :through => :datacolumns


  validates_presence_of :title, :abstract, :filename
  validates_uniqueness_of :title, :filename


  # Checks if all the cells (Measurement) saved during the upload of a
  # data sheet (ImportController) have been manually approved and
  # linked to values (eg Datetimevalue, Numericvalue, Categoricvalue,
  # Textvalue)
  def cells_linked_to_values?
    ms = self.sheetcells
    
    test = false
    unless ms.blank?
      vls = ms.collect{|m| m.value}.flatten.compact
      test = ms.length== vls.length
    end
    test
  end
  
end
