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

    def categories
    # !! Zeitfresser ??
    ms = self.sheetcells
    meas_with_cats = ms.
      collect{|m| m.value_type == "Categoricvalue"}.flatten.uniq.compact
  end


  # Are there values (Datetimevalue, Numericvalue, Categoricvalue,
  # Textvalue) associated to the measurements of this data column
  # instance?
  def values_stored?
    ms = self.sheetcells
    vls = ms.collect{|m| m.value}.compact
    return !vls.empty?
  end

   def first_five
    ms = self.sheetcells
    # Measurements are automatically added at import, but they may not
    # be linked to values yet.
    vls = ms.collect{|m| m.value}.compact
    n = vls.length
    if n > 0
      text1 = "First five of entries: "
      f_five = vls[0..4]
      begin
        f_five = f_five.collect{|vl| vl.show_value}
        text2 = "(#{f_five.to_sentence})"
        text3 = text1 + text2
      rescue
        text3 = "No entries for values found"
      end
    else
      "No values yet imported for this data column"
    end
  end


end
