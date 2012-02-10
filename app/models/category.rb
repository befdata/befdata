## Categories store naming conventions that are referenced by an instance of a "Sheetcell".
##
## Categories are linked to "Datagroup"s. The validation process ensures that Categories are unique within a "Datagroup".
class Category < ActiveRecord::Base

  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :datagroup, :class_name => "Datagroup", :foreign_key => "datagroup_id"
  has_many :sheetcells

  acts_as_taggable

  validates_presence_of :short, :long, :description
  before_validation :try_filling_missing_values

  before_destroy :check_for_sheetcells_associated
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
  
  def check_for_sheetcells_associated
    self.reload
    unless self.sheetcells.empty?
      errors.add_to_base "Cannot destroy categories with Data Cells associations"
      false
    end
  end

  def destroy_taggings
    self.taggings.destroy_all
  end

  def datasets
    Dataset.all(:conditions => ["id IN
      (SELECT DISTINCT dataset_id FROM datacolumns WHERE id IN
      (SELECT DISTINCT datacolumn_id FROM sheetcells WHERE category_id = #{self.id}
      ))"], :order => :title)
  end

end
