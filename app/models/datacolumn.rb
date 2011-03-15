class Datacolumn < ActiveRecord::Base

  is_taggable :tags, :languages
  after_destroy :destroy_taggings

  acts_as_authorization_object :subject_class_name => 'User'


  belongs_to :datagroup
  belongs_to :dataset

  has_many :sheetcells, :dependent => :destroy

  has_many :import_categoricvalues, :dependent => :destroy

  validates_presence_of :datagroup_id, :dataset_id, :columnheader, :columnnr, :definition
  validates_uniqueness_of :columnheader, :columnnr, :scope => :dataset_id

  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end

  # Returns a hash of the imported entries as value and the rownumber
  # from the Observation as key.
  def rownr_entry_hash
    ms = self.sheetcells
    rownr_entry_hash = Hash.new
    ms.each do |m|
      rownr = m.observation.rownr
      rownr_entry_hash[rownr] = m.import_value
    end
    return rownr_entry_hash
  end

  # Sorts measurements along rownr (from Observation) and then returns
  # a sorted array.
  def measurements_sorted
    # !! Zeitfresser ??
    ms = Sheetcell.find_all_by_datacolumn_id(self.id, :include => :observation)
    ms = ms.sort_by{|m| m.observation.rownr}
    # ms = self.measurements.sort_by{bm| m.observation.rownr}
    ms
  end


  # Are there values (Datetimevalue, Numericvalue, Categoricvalue,
  # Textvalue) associated to the measurements of this data column
  # instance?
  def values_stored?
    ms = self.sheetcells
    vls = ms.collect{|m| m.value}.compact
    return !vls.empty?
  end


end
