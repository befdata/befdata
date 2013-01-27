## The Datacolumn class models the Datacolumn table.
##
## A Datacolumn manages all the observations for a particular measurement which are stored in the the "Sheetcell" table.
##
## There are two particularly important methods on the Datacolumn class:
## 1. "add_data_values" validates the imported data value (import_value column in the "Sheetcell" table)
## and saves the validated value to the accepted_value column of the "Sheetcell" table in the case on non-"Category" "Datatype"s.
## If the data is of type "Category" then the validated "Category" Id is saved the in the CategoryId column of the "Sheetcell" table.
## Any unvalidated "Sheetcell" values are flagged as INVALID in the StatusId column of the "Sheetcell" table and their original uploaded
## data value remains in the import_value column "Sheetcell" table.
##
## 2. "update_invalid_value" creates a "Category" instance for the invalid value and assigns the "Category" to all "Sheetcell" instances
## that have the same invalid value in the "DataColumn". Regardless of the "Datatype" a "Category" is created for each invalid value and the
## "Datatype" of the "Sheetcell" updated to "Category". This results in Datacolumns consisting of more than one "Datatype".

require 'acl_patch'
class Datacolumn < ActiveRecord::Base
  include PgSearch
  include AclPatch
  acts_as_authorization_object :subject_class_name => 'User'
  acts_as_taggable
  after_destroy :destroy_taggings

  belongs_to :datagroup, :dependent => :destroy
  has_many :categories, :through => :datagroup
  belongs_to :dataset, :touch => true

  has_many :sheetcells, :dependent => :destroy
  has_many :import_categories, :dependent => :destroy

  validates_presence_of :datagroup_id, :dataset_id, :columnheader, :columnnr, :definition
  validates_uniqueness_of :columnheader, :columnnr, :scope => :dataset_id

  pg_search_scope :search, against: {
    columnheader: 'A',
    definition: 'B'
  }, associated_against: {
    tags: {name: 'A'},
    datagroup: {title: 'A', description: 'B'},
    categories: {short: 'A', long: 'A', description: 'B'}
  }, using: {
    tsearch: {
    dictionary: "english",
    prefix: true
  }
  }

  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end

  # Are there data values associated to the measurements of this data column instance?
  def values_stored?
    self.sheetcells.exists?(["accepted_value IS NOT NULL OR accepted_value !='' OR category_id > 0"])
  end

  # returns the first 'count' number unique imported values
  def imported_values(count)
    values = self.sheetcells.all( :order => "import_value",
                                 :limit => count,
                                 :group => "import_value",
                                 :select => "import_value")
    return values
  end

  # returns the first 'count' number unique accepted values
  def accepted_values(count)
    values = self.sheetcells.all(:limit => count,
                                 :joins => "LEFT OUTER JOIN categories ON categories.id = sheetcells.category_id" ,
                                 :select => "distinct case when sheetcells.category_id > 0 then categories.short else sheetcells.accepted_value end as accepted_value",
                                 :order => "accepted_value")

    return values
  end

  # saves the accepted values for each "Sheetcell" in the column
  # first looking for a match in existing categories
  # then looking for a match in categories from the "Dataworkbook"
  # if there are no "Category" matches then the import value is used as the accepted value
  # NB: all of the business logic is in functions within the database
  # found in db/non_schema_sql.sql
  def add_data_values(user)

    # remove any previous accepted values so that we can keep a track of what has been updated
    sqlclean = "select clear_datacolumn_accepted_values(#{id})"
    # this bit will need to change once we change the column datatype to be an integer
    case self.import_data_type
    when "text"
      datatype = Datatypehelper.find_by_id(1)
    when "year"
      datatype = Datatypehelper.find_by_id(2)
    when "date"
      datatype = Datatypehelper.find_by_id(3)
    when "category"
      datatype = Datatypehelper.find_by_id(5)
    when "number"
      datatype = Datatypehelper.find_by_id(7)
    else
      #unknown
      datatype = Datatypehelper.find_by_id(8)
    end
    # I would like to change this so that the SQL is in one function but it wasn't working
    # TODO: I will look at this again - SR
    if(datatype.name == "text") then
      sql = "select accept_text_datacolumn_values(#{id})"
    else
      dataset = Dataset.find(self.dataset_id)
      comment = ""
      unless dataset.nil?
        comment = dataset.title
      end
      sql = "select accept_datacolumn_values(#{datatype.id}, #{id}, #{datagroup_id}, #{user.id}, '#{comment}')"
    end

    begin
      connection = ActiveRecord::Base.connection()
      connection.begin_db_transaction
      connection.execute(sqlclean)
      connection.execute(sql)

      connection.commit_db_transaction
    rescue
      connection.rollback_db_transaction
      raise
    end

  end

  def approve_datagroup(datagroup)
    self.datagroup = datagroup
    self.datagroup_approved = true
    self.datatype_approved = false
    self.finished = false
    self.save
  end

  def approve_datatype(datatype, user)
    # selecting a datatype means that the imported values can validated against the datatype.
    self.import_data_type = datatype
    self.add_data_values(user)

    self.datatype_approved = true
    self.finished = false
    self.save
  end

  def has_invalid_values?
    self.sheetcells.where(status_id: Sheetcellstatus::INVALID).count > 0
  end

  # returns the unique invalid uploaded sheetcells
  def invalid_values
    #TODO check for memory consumption
    # get all the invalid sheetcells
    invalid_sheetcells = self.sheetcells.all( :order => "import_value",
                                             :conditions => ["status_id = ?", Sheetcellstatus::INVALID],
                                             :group => "import_value",
                                             :select => "import_value")

    # No need to order the sheetcells if none were found
    return Hash.new if invalid_sheetcells.blank?

    # Create a new array
    invalid_values = Hash.new
    invalid_sheetcells.each_with_index{|sc, i|
      invalid_values[sc.import_value] = i
    }
    return invalid_values
  end

  # returns any invalid sheetcells with the given value
  def invalid_sheetcells_by_value(value)
    #Todo check for memory consumption
    return self.sheetcells.all( :conditions => ["status_id = ? AND import_value=?",
                               Sheetcellstatus::INVALID, value])
  end

  # creates a category for the invalid value and assigns the category to all matching sheetcells
  def update_invalid_value(original_value, short, long, description, user, dataset)
    # firstly check that the category doesn't already exist in the datagroup
    cat = Category.first(:conditions => ["datagroup_id = ? and short = ?",
                         self.datagroup.id,
                         short]
                        )
                        if(cat.nil?)
                          cat = Category.create(:short => short,
                                                :long => long,
                                                :description => description,
                                                :status_id => Categorystatus::MANUALLY_APPROVED,
                                                :user_id => user.id,
                                                :datagroup => self.datagroup,
                                                :comment => dataset.title)
                        end
                        # update all invalid sheetcells with the same original value with the new category id
                        if(cat.valid?)
                          cells = invalid_sheetcells_by_value(original_value)
                          if(!cells.nil?)
                            cells.each do |cell|
                              cell.update_attributes(:category => cat,
                                                     :status_id => Sheetcellstatus::VALID,
                                                     :accepted_value => nil,
                                                     :datatype_id => Datatypehelper.find_by_name("category").id
                                                    )
                            end
                          end

                          #TODO not sure if this should really go here - Sophia
                          # update any other invalid values for columns with the same datagroup as they may contain the same values
                          columns = Datacolumn.all( :conditions => ["datagroup_id = ? and dataset_id = ?",
                                                   self.datagroup.id, self.dataset.id])
                          if(!columns.nil?)
                            columns.each do |col|
                              cells = col.invalid_sheetcells_by_value(original_value)
                              if(!cells.nil?)
                                cells.each do |cell|
                                  cell.update_attributes(:category => cat,
                                                         :status_id => Sheetcellstatus::VALID,
                                                         :accepted_value => nil,
                                                         :datatype_id => Datatypehelper.find_by_name("category").id
                                                        )
                                end
                              end
                            end
                          end
                        end
                        self.finished = false
  end

  # this should not be happen but we thought it might be a good last step before we can
  # confirm the dataset as completely approved
  def final_check_for_valid_sheetcells
    if self.sheetcells.where(:status_id => Sheetcellstatus::INVALID).count != 0
      self.finished = false
      self.save
      return false
    end

    self.finished = true
    self.save
    true
  end

  def to_label
    columnheader
  end

  def approval_stage
    stage = '0'
    stage = '1' if self.datagroup_approved
    stage = '2' if self.datagroup_approved && self.datatype_approved
    stage = '3' if self.datagroup_approved && self.datatype_approved && !self.has_invalid_values?
    stage = '4' if self.datagroup_approved && self.datatype_approved && !self.has_invalid_values? && self.finished
    stage
  end

  def untouched?
    approval_stage == '0' && finished == false
  end

  def split_me?(separate_category_columns = false)
    # This method returns true for a column when it requires splitting.

    collect_column_sheetcells_boolean_values = []

    self.sheetcells.each do |sc|
      if self.import_data_type == 'category' || !(sc.datatype && sc.datatype.is_category? && sc.category)
        collect_column_sheetcells_boolean_values << false
      else
        collect_column_sheetcells_boolean_values << true
      end
    end

    if collect_column_sheetcells_boolean_values.include?(true)
      return true
    else
      return false
    end
  end

  # acl9 related stuff: users

  # users of a datacolumn are those who are responsible for it
  # = for monkey patch of acl 9
  def users= (people)
    self.set_user_with_role(:responsible, people)
  end
end
