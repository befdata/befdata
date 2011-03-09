## The class "Categoricvalue" contains categoric values. It is one of
## the tables fitting in the "Value_type" and "Value_id" in the table
## with all the measurements (Measurement). The other possibles entry types are
## Numericvalue,  Datetimevalue, PersonRole, and Textvalue

class Categoricvalue < ActiveRecord::Base
 

  include FuzzySearch
  fuzzy_search_attributes :short, :long


  has_many :measurements, :as => :value
  ## if there is any measurement linked to a category,
  ## it should not be destroyed; If there is a reason to change this
  ## category, it should only be changed
  ## before_destroy :no_measurement_linked?
  has_many :import_categories

  # tagging
  is_taggable :tags, :languages

  validates_presence_of :short, :long, :description
  ## does not work, no "column" "data_group"... p. 398 in the rails book has 
  ## solution
  ## validates_uniqueness_of :short, :long, :description, :scope => :data_group
  ## within one method, categories should be unique
  ## categoricvalues are linked via measurements - submethods to methods

  before_destroy :check_for_measurements, :check_for_import_categories
  after_destroy :destroy_taggings


  def data_groups
    # should be one!
    # !Zeitfresser!
    dgs = self.measurements.
      collect{|data_cell| data_cell.measurements_methodstep.methodstep}
    dgs = dgs.flatten.uniq
  end


  def data_group
    self.data_groups[0]
  end



  def destroy_taggings
    logger.debug "in destroy taggings"
    cds = self.taggings.destroy_all
  end

  def check_for_measurements
    puts "in check for measurements"
    cat = self.reload
    unless cat.measurements.length == 0
      puts "measurements linked"
      errors.add_to_base "Cannot destroy categoric value with Data Cells associations"
      false
    end
  end

  def check_for_import_categories
    puts "in check for import categories"
    cat = self.reload
    unless cat.import_categories.length == 0
      puts "import categories linked"
      errors.add_to_base "Cannot destroy categoric value with Import Categories associations"
      false
    end
  end


  def show_value
    "#{long} (#{short})"
  end

  def verbose
    "#{short} -- #{long} -- #{description}"
  end

  protected

  ## def no_measurement_linked?
  ##  self.measurements.length == 0
  # so how do I say something, if this is not the case?
  ## end

end
