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
  # acts_as_authorization_object :subject_class_name => 'Project'

  is_taggable :projecttags   # deprecated
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


  # This method delete all necessary object which containts to this dataset
  # so its possible to upload a new datafile
  def clean
    dataset_sheetcells = self.sheetcells
    sheetcells_with_cat_values = dataset_sheetcells.select{|sc| sc.value_type == "Categoricvalue"}
    sheetcells_without_cat_values =dataset_sheetcells.select{|sc| sc.value_type != "Categoricvalue"}
    uniq_categoricvalues = sheetcells_with_cat_values.collect{|sc| sc.value}.uniq
    uniq_values_without_catvals = sheetcells_without_cat_values.collect{|sc| sc.value}.uniq.compact

    # observations are destroyed with sheetcells

    dataset_sheetcells.each{|sc| sc.destroy}
    uniq_categoricvalues.each{|cat| cat.destroy}
    uniq_values_without_catvals.each{|value| value.destroy}

    datacolumns = self.datacolumns
    import_categories = datacolumns.collect{|dc| dc.import_categoricvalues}.flatten.compact
    uniq_categoricvalues = import_categories.collect{|ic| ic.categoricvalue}.uniq.compact
    import_categories.each{|t| t.destroy}
    uniq_categoricvalues.each{|cat| cat.destroy}

    datacolumns.each do |datacolumn|
      # accepted_roles are destroyed by acl9
      datagroup = datacolumn.datagroup
      if datagroup.datacolumns.length == 1
        datagroup.destroy
      end
      datacolumn.destroy
    end

    datafile = self.upload_spreadsheet
    if datafile
      datafile.destroy
    end


    freeformats = self.freeformats
    freeformats.each{|freeformat| freeformat.destroy}
  end
  
end
