# This file contains the Context model, which maps the data base table
# contexts for the application.  Contexts contain the general meta
# data of a data set and link to data values as well as to provenance
# tables.


# Information in Context specify the general metadata for a data set
# available on the data portal.  This includes meta data such as title
# and abstract.  Additionally, instances of Context are linked to the
# originators of the data set (see ContextPersonRole, PersonRole,
# Person).
#
# Primary research data as well as custom format files are linked to
# contexts.  Primary research data is given in a flat file format,
# consisting of rows and columns.  Columns store similar data, for
# example tree height or detailed information on location (see
# MeasurementsMethodstep, Admin::MeasurementsMethodstepsController).
#
# Members of the research unit can request data from contexts by
# submitting a DataRequest (see also DataRequestsController).  After
# having successfully submitted a data request, people are listed in
# ContextFreeperson (see also ContextFreepeopleController).
#
# !! not yet implemented: Downloads of contexts are stored in a
# !! separate table (ContextDownload, see also
# !! ContextDownloadsController).
#
# Contexs, as well as the models Methodstep, MeasurementsMethodstep,
# and Categoricvalue are taggable, that is, they can be linked to an
# entry in the tags table.  This uses the is_taggable rails gem.
#
# To use full text search on contexts, we currently use the
# acts_as_ferret rails gem.
#
# Contexts, as ActiveRecord Objects, map the data base table
# "contexts" so that it can be used in the web application.  With it,
# all fieldnames of the data base table become accessible as
# attributes of a context.

class Dataset < ActiveRecord::Base

  acts_as_authorization_object :subject_class_name => 'User'

  is_taggable :projecttags   # deprecated #TODO this is used in the download action -> but marked as deprecated
  is_taggable :tags, :languages

  belongs_to :upload_spreadsheet, :class_name => "Datafile",
                                  :foreign_key => "upload_spreadsheet_id",
                                  :dependent => :destroy

  has_many :datacolumns, :dependent => :destroy, :order => "columnnr"
  has_many :sheetcells, :through => :datacolumns
  has_many :freeformats, :dependent => :destroy

  has_many :dataset_projects
  has_many :projects, :through => :dataset_projects


  validates_presence_of :title, :abstract, :filename
  validates_uniqueness_of :title, :filename




  # Checks if all the cells (Measurement) saved during the upload of a
  # data sheet (ImportController) have been manually approved and
  # linked to values (eg Datetimevalue, Numericvalue, Categoricvalue,
  # Textvalue)
  def cells_linked_to_values?
    sheetcells = self.sheetcells.all(:conditions => ["accepted_value IS NOT NULL OR accepted_value !='' OR category_id > 0"])
    !sheetcells.empty?
  end

  # During the import routine, we step through each of the data
  # columns using their header.
  def headers
    self.datacolumns.collect{|dc| dc.columnheader}
  end

  def finished_datacolumns
    datacolumns.select{|dc| dc.finished == true}
  end
  
  def datacolumns_with_approved_datagroup
    datacolumns.select{|dc| dc.datagroup_approved == true}
  end

  def datacolumns_with_approved_datatype
    datacolumns.select{|dc| dc.datatype_approved == true}
  end
  
  def predefined_columns
    # To be predefined, a column must have a datagroup and a datatype that is not 'unknown'.
    # The datagroup is created at import, so we only have to check for the datatype.
    # Furthermore, the datacolumn approval process must not have already started.
    datacolumns.select{|dc| Datatypehelper.find_by_name(dc.import_data_type) != 'unknown' && dc.untouched?}
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


  # This method delete all necessary object which containts to this dataset
  # so its possible to upload a new datafile
  def clean
    self.datacolumns.destroy_all
    self.upload_spreadsheet.destroy

    #TODO @daniel please check and remove if not needed anymore in #4772
    #dataset_sheetcells = self.sheetcells
    #sheetcells_with_cat_values = dataset_sheetcells.select{|sc| sc.datatype.name=="Category"}
    #sheetcells_without_cat_values = dataset_sheetcells.select{|sc| sc.datatype.name!="Category"}
    #uniq_categories = sheetcells_with_cat_values.collect{|sc| sc.value}.uniq
    #uniq_values_without_catvals = sheetcells_without_cat_values.collect{|sc| sc.accepted_value}.uniq.compact
    #
    ## observations are destroyed with sheetcells
    #
    #dataset_sheetcells.each{|sc| sc.destroy}
    #uniq_categories.each{|cat| cat.destroy}
    #uniq_values_without_catvals.each{|value| value.destroy}
    #
    #datacolumns = self.datacolumns
    #import_categories = datacolumns.collect{|dc| dc.import_categories}.flatten.compact
    #uniq_categoricvalues = import_categories.collect{|ic| ic.category}.uniq.compact
    #import_categories.each{|t| t.destroy}
    #uniq_categoricvalues.each{|cat| cat.destroy}
    #
    #datacolumns.each do |datacolumn|
    #  # accepted_roles are destroyed by acl9
    #  datagroup = datacolumn.datagroup
    #  if datagroup.datacolumns.length == 1
    #    datagroup.destroy
    #  end
    #  datacolumn.destroy
    #end
    #
    #datafile = self.upload_spreadsheet
    #if datafile
    #  datafile.destroy
    #end
  end

  def owners
    self.users.select{|u| u.has_role?(:owner, self)}
  end
  
end
