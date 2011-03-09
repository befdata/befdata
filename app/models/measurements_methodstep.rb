# A Submethod or MeasurementsMethodstep links Methodstep entries to a Context. In
# Methodstep you find more general information on the method
# used. MeasurementsMethodstep adds finer information. It is basically
# the column in a spreadsheet submitted to the project. One Methodstep
# can be reused in different Context entries, while
# MeasurmentsMethodstep is specific to a single
# Context. MeasurmentsMethodstep may have many entries of
# MeasmethsPersonrole, which links to possibly many researchers
# (Person) who have performed the measurements.
#
# This table contains information on
# * Methodstep and Context
# * columnheader in the original file, column number in that file
# * definition of that columnheader
# * the unit of measurement: meter, degree, etc, see http://nb.ecoinformatics.org/software/eml/eml-2.1.0/eml-unitTypeDefinitions.html
# * a missing value code
#
# inspired by http://knb.ecoinformatics.org/software/eml/eml-2.1.0/eml-methods.html

class MeasurementsMethodstep < ActiveRecord::Base

  acts_as_authorization_object :subject_class_name => 'Person'

  belongs_to :methodstep
  belongs_to :context

  ##################################################################################
  # Here the Roles a Person could have to this Object:                             #
  # :responsible                                                                   #
  ##################################################################################
  acts_as_authorization_object :subject_class_name => 'Person'

  has_many :measmeths_personroles, :dependent => :destroy
  has_many :measurements, :dependent => :destroy

#  has_many :person_roles, :through => :measmeths_personroles
  has_many :import_categories, :dependent => :destroy

  has_many :data_request_contexts
  has_many :data_requests, :through => :data_group_data_requests

  acts_as_authorization_object :subject_class_name => 'Person'

  validates_presence_of :methodstep_id, :context_id,
    :columnheader, :columnnr, :definition
  validates_uniqueness_of :columnheader, :columnnr, :scope => :context_id

  acts_as_ferret :fields => [:columnheader, :definition, :comment]

  is_taggable :tags, :languages


  after_destroy :destroy_taggings


  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end


  # This method provides a nice look of MeasurementsMethodstep in admin views
  def to_label
    "#{columnheader}"
  end

  # This method provides a nice look of MeasurementsMethodstep in admin views
  def long_label
    "(#{columnheader}, id: #{id}) #{definition}"
  end


  # Sorts measurements along rownr (from Observation) and then returns
  # a sorted array.
  def measurements_sorted
    # !! Zeitfresser ??
    ms = Measurement.find_all_by_measurements_methodstep_id(self.id, :include => :observation)
    ms = ms.sort_by{|m| m.observation.rownr}
    # ms = self.measurements.sort_by{bm| m.observation.rownr}
    ms
  end

  def categories
    # !! Zeitfresser ??
    ms = self.measurements
    meas_with_cats = ms.
      collect{|m| m.value_type == "Categoricvalue"}.flatten.uniq.compact
  end


  # Returns a hash of the imported entries as value and the rownumber
  # from the Observation as key.
  def rownr_entry_hash
    ms = self.measurements
    rownr_entry_hash = Hash.new
    ms.each do |m|
      rownr = m.observation.rownr
      rownr_entry_hash[rownr] = m.import_value
    end
    return rownr_entry_hash
  end

  # Are there values (Datetimevalue, Numericvalue, Categoricvalue,
  # Textvalue) associated to the measurements of this data column
  # instance?
  def values_stored?
    ms = self.measurements
    vls = ms.collect{|m| m.value}.compact
    return !vls.empty?
  end


  def first_five
    ms = self.measurements
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


  def to_s # :nodoc:
    to_label
  end

  def authorized_for_create? # :nodoc:
    if current_user
      return true if current_user.has_role?('admin')
    else
      return false
    end
  end

  def authorized_for_read? # :nodoc:
    return true unless existing_record_check?
    if current_user
      return true if current_user.has_role?('admin') || self.context.context_person_roles.map{|cpr| cpr.person_role.person}.uniq.include?(current_user)
    else
      return false
    end
  end

  def authorized_for_update? # :nodoc:
    return true unless existing_record_check?
    if current_user
      return true if current_user.has_role?('admin') || self.context.context_person_roles.map{|cpr| cpr.person_role.person}.uniq.include?(current_user)
    else
      return false
    end
  end

  def authorized_for_destroy? # :nodoc:
    if current_user
      return true if current_user.has_role?('admin')
    else
      return false
    end
  end
end
