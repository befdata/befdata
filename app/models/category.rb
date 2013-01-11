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
  after_update :update_dataset

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
    sc = self.sheetcells(true)
    unless sc.empty? || (sc.count == 1 && sc.first.destroyed?)
      false
    end
  end

  def destroy_taggings
    self.taggings.destroy_all
  end

  # find and update the updated_at date for all datasets that share this category
  def update_dataset
    sql = "select update_date_category_datasets(#{id})"
    connection = ActiveRecord::Base.connection()
    connection.execute(sql)
  end

  def update_sheetcells_with_csv(file, user)
    begin
      lines = CSV.read file
    rescue
      errors.add :file, 'can not be read' and return false
    end
    lines = validate_and_reduce_sheetcells_csv(lines)
    return if !lines || !errors.blank?

    update_overview = split_sheetcells_category(lines, user)
    unless update_overview.blank?
      self.comment = "#{self.comment} Split via CVS by #{user.lastname}, #{Time.now.to_s}.".strip
      self.save
    end
    update_overview
  end

private

  def validate_and_reduce_sheetcells_csv(csv_lines)
    if csv_lines[0].nil?
      errors.add :csv, 'seems to be empty' and return false
    end

    unless csv_lines[0][0] == 'ID'
      errors.add :csv, 'header does not match' and return false
    end

    unless csv_lines[0].length == 5
      errors.add :csv, 'has wrong number of columns' and return false
    end

    # clean header from csv / allow empty lines
    csv_lines.delete_at 0
    csv_lines.delete_if {|l| l.compact.empty?}

    if csv_lines.empty?
      errors.add :csv, 'no categories given' and return false
    end

    csv_sheetcell_ids = csv_lines.collect{|l| l[0].to_i}

    unless csv_sheetcell_ids.uniq!.nil?
      errors.add :csv, 'IDs must be unique' and return false
    end

    cat_sheetcell_ids = self.sheetcells.collect{|s| s.id}

    sheetcells_no_match = csv_sheetcell_ids - cat_sheetcell_ids
    unless sheetcells_no_match.empty?
      errors.add :csv, "sheetcell #{sheetcells_no_match} not found in category" and return false
    end

    csv_lines.each do |l|
      if l[0].blank?
        errors.add :csv, 'ID must not be empty' and return false
      end
    end
  end

  def split_sheetcells_category(csv_lines, user)
    pairs = csv_lines.reject{|l| l[4].blank?}.collect {|l| [l[0].to_i, l[4].strip]}
    updates_overview = Array.new
    altered_cats = Array.new
    pairs.each do |p|
      existing_cat = Category.find_by_datagroup_id_and_short self.datagroup_id, p[1]
      if existing_cat
        if existing_cat == self
          updates_overview << [p[0], 'already', nil, nil]
        else
          s = Sheetcell.find(p[0])
          s.category = existing_cat
          s.save
          altered_cats << existing_cat
          updates_overview << [p[0], 'added', existing_cat.id, existing_cat.short]
        end
      else
        new_category = Category.new
        new_category.short = p[1]
        new_category.datagroup = self.datagroup
        new_category.save
        s = Sheetcell.find(p[0])
        s.category = new_category
        s.save
        altered_cats << new_category
        updates_overview << [p[0], 'new', new_category.id, new_category.short]
      end
    end

    comment_string = "Added sheetcells via CVS by #{user.lastname}, #{Time.now.to_s}.".strip
    altered_cats.uniq.each do |c|
      c.comment = "#{c.comment} #{comment_string}".strip
      c.save
    end
    updates_overview
  end

end
