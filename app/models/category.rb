class Category < ActiveRecord::Base

  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :datagroup, :class_name => "Datagroup", :foreign_key => "datagroup_id"
  has_many :sheetcells
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
  ## categories are linked via measurements - submethods to methods

  before_destroy :check_for_measurements, :check_for_import_categories
  after_destroy :destroy_taggings

  ## !! before save we should check if all is given: short, long, description

  def verbose
    "#{short} -- #{long} -- #{description}"
  end

  def show_value
    "#{long} (#{short})"
  end
  
  def check_for_measurements
    puts "in check for measurements"
    cat = self.reload
    unless cat.sheetcells.length == 0
      puts "measurements linked"
      errors.add_to_base "Cannot destroy categories with Data Cells associations"
      false
    end
  end

  def check_for_import_categories
    puts "in check for import categories"
    cat = self.reload
    unless cat.import_categories.length == 0
      puts "import categories linked"
      errors.add_to_base "Cannot destroy categories with Import Categories associations"
      false
    end
  end

  def destroy_taggings
    logger.debug "in destroy taggings"
    cds = self.taggings.destroy_all
  end

end
