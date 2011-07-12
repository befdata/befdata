class Datacolumn < ActiveRecord::Base

  is_taggable :tags, :languages
  after_destroy :destroy_taggings

  acts_as_authorization_object :subject_class_name => 'User'


  belongs_to :datagroup
  belongs_to :dataset

  has_many :sheetcells, :dependent => :destroy

  has_many :import_categories, :dependent => :destroy

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
    ms = Sheetcell.find_all_by_datacolumn_id(self.id, :include => :observation, :include => :category)
    ms = ms.sort_by{|m| m.observation.rownr}
    # ms = self.measurements.sort_by{bm| m.observation.rownr}
    ms
  end

  # Are there categories associated to the measurements of this data column instance?
  def has_categories_uploaded
    ms = self.sheetcells.find(:all, :conditions => ["category_id > 0"])
    return !ms.empty?
  end

  # Are there values associated to the measurements of this data column instance?
  def values_stored?
    ms = self.sheetcells.find(:all, :conditions => ["accepted_value IS NOT NULL OR accepted_value !='' OR category_id > 0"])
    return !ms.empty?
  end

  # returns the first 'count' number unique imported values
  def imported_values(count)
    values = self.sheetcells.find(:all, :order => "import_value",
                                        :limit => count,
                                        :group => "import_value",
                                        :select => "import_value")
    return values
  end

  # returns the first 'count' number unique accepted values
  def accepted_values(count)
    if(self.values_stored?)
      values = self.sheetcells.find(:all, :limit => count,
                                          :joins => "LEFT OUTER JOIN categories ON categories.id = sheetcells.category_id" ,
                                          :select => "distinct case when sheetcells.category_id > 0 then categories.short else sheetcells.accepted_value end as accepted_value",
                                          :order => "accepted_value")

      return values
    else
      return "No values yet imported for this data column"
    end
  end

  # This method provides a nice look of MeasurementsMethodstep in admin views
  def long_label
    "(#{columnheader}, id: #{id}) #{definition}"
  end

  # saves the accepted values for each sheetcell in the column
  # first looking for a match in existing categories
  # then looking for a match in categories from the datasheet
  # if there are no category matches then the import value is used as the accepted value
  # NB: all of the business logic is in functions within the database
  def add_data_values()

    # store the system data group id as this makes the SQL faster since it's one less join
    scm_datagroup_id = Datagroup.sheet_category_match.first.id if !Datagroup.sheet_category_match.first.nil?
    # remove any previous accepted values so that we can keep a track of what has been updated
    sqlclean = "select clear_datacolumn_accepted_values(#{id})"
    # this bit will need to change once we change the column datatype to be an integer
    case self.import_data_type
        when "text"
          datatype_id = 1
        when "year"
          datatype_id = 2
        when "date(2009-07-14)"
          datatype_id = 3
        when "date(14.07.2009)"
          datatype_id = 4
        when "category"
          datatype_id = 5
        else
          datatype_id = 7    # number
      end
    # I would like to change this so that the SQL is in one function but it wasn't working
    # I will look at this again - SR
    if(datatype_id == 1)then
      sql = "select accept_text_datacolumn_values(#{id})"
    else
      sql = "select accept_datacolumn_values(#{datatype_id}, #{id}, #{datagroup_id}, #{scm_datagroup_id})"
    end

    begin
      connection = ActiveRecord::Base.connection();
      connection.begin_db_transaction
      connection.execute(sqlclean)
      connection.execute(sql)

      connection.commit_db_transaction
    rescue
      connection.rollback_db_transaction
      raise
    end

  end

  # returns all the invalid uploaded sheetcells
  def invalid_values
    return self.sheetcells.find(:all, :conditions => ["status_id = ?", Sheetcellstatus::INVALID])
  end

  # returns all unique categories available in the portal or the sheet for this column
  def available_categories

  end

end
