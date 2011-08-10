## Categories are values that can be reused by sheetcells.  They enable the construction of a
## controlled vocabulary within the portal.
class Category < ActiveRecord::Base

  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :datagroup, :class_name => "Datagroup", :foreign_key => "datagroup_id"
  has_many :sheetcells
  has_many :import_categories

  is_taggable :tags, :languages

  validates_presence_of :short, :long, :description
  before_validation :try_filling_missing_values

  before_destroy :check_for_measurements, :check_for_import_categories
  after_destroy :destroy_taggings


  def try_filling_missing_values
    if self.short then
      self.long ||= self.short
      self.description ||= self.long
    end
  end

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
