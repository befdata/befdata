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

  # During the import routine, we step through each of the data
  # columns using their header.
  def headers
    # should be sorted by columnnr
    self.datacolumns.collect{|dc| dc.columnheader}
  end

  # The class Observation stores all rows of the primary data sheets
  # uploaded to the data portal.  Here a hash is constructed that
  # stores the observation ID as value and the rownr as key.
  def rownr_observation_id_hash
    o_ids = self.observation_ids
    os = Observation.find(o_ids)
    rownr_obs_id = Hash.new
    os.each do |o|
      rownr_obs_id[o.rownr] = o.id
    end
    return rownr_obs_id
  end

  # The class Observation stores all rows of the primary data sheets
  # uploaded to the data portal.  This method collects all the unique
  # IDs of observations linked to a context. !Zeitschlucker?!
  def observation_ids
    self.sheetcells.collect{|cell| cell.observation_id}.uniq
  end

  # This is a virtual column to display the count of downloads of this
  # dataset.  !! this column should be replaced by an own link tabel
  # dataset_downloads
  def download_counter
    "Downloads: #{self.downloads}"
  end
  
end
