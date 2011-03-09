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

class Context < ActiveRecord::Base
  acts_as_ferret :fields => [:abstract, :comment, :dataanalysis, :title]

  ###########################################################################
  # Here the Roles a Person could have to this Object:                      #
  # :owner, :proposer, :silent_owner, :invited_person, :invited_via_project #
  ###########################################################################
  acts_as_authorization_object :subject_class_name => 'Person'

  has_many :person_roles, :through => :context_person_roles , :include => [:person, :role, :project] 
  # the include may not be needed each time this is called?
  has_many :context_person_roles, :dependent => :destroy
  has_many :context_freepeople, :dependent => :destroy
  has_many :context_freeprojects, :dependent => :destroy
  has_many :measurements_methodsteps, :dependent => :destroy, :order => "columnnr"
  has_many :measurements, :through => :measurements_methodsteps
  belongs_to :upload_spreadsheet, :class_name => "Filevalue", 
                                  :foreign_key => "upload_spreadsheet_id"

  is_taggable :projecttags


  ## either temporal extent, or both: date min and date max should be
  ## given, the filename is the one that will be used when exporting
  ## the resulting file, so it is also still needed, even if there is
  ## an upload_filevalue for the context.
  validates_presence_of :title, :abstract, :filename
  validates_uniqueness_of :title, :filename
  # validates_associated -> should be handled by the link tables

  # make sure that there is somebody responsible for the contex. This should
  # be somebody having at least postdoc/PI/co-Pi/speaker status
  # this must be done after save, since otherwise no valid personrole can
  # be added
  # after_save :any_person_responsible?

  # tagging
  is_taggable :tags, :languages

  after_destroy :destroy_taggings, :destroy_workbook_file

  # enable stepping through headers
  attr_writer :current_header

  # Remembering the current header of the data column that is imported
  # or annotated
  def current_header
    @current_header || headers.first
  end

  def query_by_role(role_name)
  corresponding_role_ids = self.accepted_roles.all(:conditions => { :name => role_name }).map(&:id)

  # this will now return all users that have +role_name+ on +object+
  Person.all(:include => :roles, :conditions => ['roles.id IN (?)', corresponding_role_ids])
  end

  # During the import routine, we step through each of the data
  # columns using their header.
  def headers
    # should be sorted by columnnr
    self.measurements_methodsteps.collect{|dc| dc.columnheader}
  end


  # Remove all taggings of a context.  This has to be done after
  # deleting a context.  Taggings only link to the tag table, so that
  # the tags themselves are not destroyed.
  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end


  def to_label
    self.title
  end


  # During upload in the ContextsController and ImportController,
  # values are read in from an Excel workbook, which is saved along
  # the way.  This is deleted here.
  def destroy_workbook_file
    logger.debug "in destroy_workbook_file"
    f_name = self.filename
    file = Filevalue.find_by_file_file_name(f_name)
    file.destroy if file
    logger.debug "leaving destroy_workbook_file"
  end



  # The class Observation stores all rows of the primary data sheets
  # uploaded to the data portal.  This method collects all the unique
  # IDs of observations linked to a context. !Zeitschlucker?!
  def observation_ids
    self.measurements.collect{|cell| cell.observation_id}.uniq
  end

  # Checks if all the cells (Measurement) saved during the upload of a
  # data sheet (ImportController) have been manually approved and
  # linked to values (eg Datetimevalue, Numericvalue, Categoricvalue,
  # Textvalue)
  def cells_linked_to_values?
    ms = self.measurements
    test = false
    unless ms.blank?
      vls = ms.collect{|m| m.value}.flatten.compact
      test = ms.length== vls.length
    end
    test
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



  # This is a virtual column to display the count of downloads of this
  # context.  !! this column should be replaced by an own link tabel
  # context_downloads
  def download_counter
    "Downloads: #{self.downloads}"
  end

  # A Vip is a Person that may download the whole context. These come
  # from the ContextPersonRole and the associated Project.
  def vips
    # Get all PersonRole objects first, to avoid multiple db queries
    @people ||= PersonRole.find(:all, :include => [:person, :role, :project])
    # Allowed roles
    allowed = ['pi', 'co-pi', 'speaker']
    # All ContextPersonRole are obvisously vips
    vips = self.context_person_roles.map{|cpr| cpr.person_role}
    # The context is bound to the respective projects of the ContextPersonRole
    projects = vips.map{|pr| pr.project}
    projects.each do |p|
      # Every vip in this project is allowed, too
      vips += @people.select{|pr| pr.project == p && allowed.include?(pr.role.name)}
    end

    # Admins are vips, too.
    vips += @people.select{|pr| pr.person.has_role?('admin')}

    # Return the vips without the duplicates
    return vips.uniq
  end



  # A Vop is a Person that may not download the full context, but
  # their personal parts of it. This set is disjoint with the set of
  # fundings.
  def vops

    vops = self.measurements_methodsteps.map{|mm| mm.measmeths_personroles}.flatten.uniq.map{|mmpr| mmpr.person_role}.reject{|pr| pr.role.blank? || pr.role.name == "funding source"}

    ## add free people, for people that can download a given context,
    ## which is free for them
    vop2 = self.context_freepeople.collect{|cfp| cfp.person.person_roles}
    vop2 = vop2.flatten.uniq

    ## add person roles, that belong to projects that have the right
    ## to download
    vop3 = self.context_freeprojects.collect{|cfpr| cfpr.project.person_roles}
    vop3 = vop3.flatten.uniq

    vops = vops + vop2 + vop3
    vops = vops.uniq

    # This is actually an array of PersonRole
    return vops
  end


  def data_requester_from_data_columns_include?(current_user)
    data_requests_used_this_context = self.measurements_methodsteps.map{|data_column| data_column.data_requests}.flatten

    #only final ones
    final_data_requests = data_requests_used_this_context.select{|data_request| data_request.board_state == "final"}.uniq
    all_authors = final_data_requests.map{|data_request| data_request.authors  + [data_request.author]}.flatten.uniq

    all_authors.include?(current_user) ? true : false
  end

  # Fundings collect people (an array of person roles, see PersonRole)
  # that may not download any real content, but an extra distilled
  # "Virtual Context". This set of people is disjoint with the set of
  # vops.
  def fundings

    fundings = self.measurements_methodsteps.map{|mm| mm.measmeths_personroles}.flatten.uniq.map{|mmpr| mmpr.person_role}.select{|pr| pr.role.name == "funding source"}

    # This is actually an array of PersonRole
    return fundings
  end


  # If the current user can be considered "vip" for a context, she/he
  # may read.
  def authorized_for_read? # :nodoc:
    if current_user
      return true unless existing_record_check?
      return true if current_user.has_role?('admin')

      vip = false
      @roles = current_user.person_roles
      @roles.each do |r|
        vip = true if self.vips.include?(r)
      end

      return true if vip
    else
      return false
    end
  end

  # If the current user can be considered "vip", she/he may update.
  def authorized_for_update? # :nodoc:
    if current_user
      return true unless existing_record_check?
      return true if current_user.has_role?('admin')
      vip = false
      roles = current_user.person_roles
      roles.each do |r|
        vip = true if self.vips.include?(r)
      end

      return true if vip
    else
      return false
    end
  end

protected

#  def any_person_responsible?
#    rs = self.context_person_roles.collect { |cpr|  cpr.person_role.role}
#    rs = rs.uniq
#    rs.include?(one of "speaker" "pi" "copi" "postdoc")
#    give out mistake message if not
#  end

end


