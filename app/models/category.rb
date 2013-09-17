## Categories store naming conventions that are referenced by an instance of a "Sheetcell".
##
## Categories are linked to "Datagroup"s. The validation process ensures that Categories are unique within a "Datagroup".
class Category < ActiveRecord::Base

  belongs_to :datagroup, :class_name => "Datagroup", :foreign_key => "datagroup_id"
  has_many :sheetcells

  validates_presence_of :short, :long, :description
  before_validation :try_filling_missing_values

  before_destroy :check_for_sheetcells_associated
  after_update :update_dataset

  def self.delete_orphan_categories
    # delete categories that has no assciated sheetcells
    to_be_deleted = Category.joins('left outer join sheetcells on sheetcells.category_id = categories.id').
              where('sheetcells.category_id is NULL')
    puts "#{to_be_deleted.count} categories is deleted at #{Time.now.utc}" unless to_be_deleted.empty?
    Category.delete(to_be_deleted)
  end

  def try_filling_missing_values
    if self.short then
      self.long = self.short if self.long.blank?
      self.description = self.long if self.description.blank?
    end
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

  def self.search(search)
    if search
      where('short iLIKE :q OR long iLIKE :q OR description iLIKE :q', :q => "%#{search}%")
    else
      scoped
    end
  end

  # find and update the updated_at date for all datasets that share this category
  def update_dataset
    sql = "select update_date_category_datasets(#{id})"
    connection = ActiveRecord::Base.connection()
    connection.execute(sql)
  end

  def update_sheetcells_with_csv(file, user)
    begin
      lines = CSV.read(file, CsvData::OPTS)
    rescue
      errors.add :file, 'can not be read' and return false
    end
    return false if validate_sheetcells_csv?(lines)

    update_overview = split_sheetcells_category(lines, user)
    unless update_overview.blank?
      self.comment = "#{self.comment} Split via CVS by #{user.lastname}, #{Time.now.to_s}.".strip
      self.save
    end
    update_overview
  end

  def self.merge(from_category, to_category, user)
    return unless from_category.datagroup_id == to_category.datagroup_id

    comment_string = "Merged #{from_category.short} by #{user.lastname} at #{Time.now.to_s} via CSV; "
    from_category.sheetcells.update_all(:category_id => to_category.id)
    to_category.update_attributes(:comment => "#{to_category.comment} #{comment_string}".strip) # this triggers regeneration of datasets
    from_category.delete
  end

private

  def validate_sheetcells_csv?(csv_lines)
    errors.add :csv, 'seems to be empty' and return false if csv_lines.empty?
    unless (['ID'  ,'IMPORT VALUE'  ,'COLUMNHEADER'  ,'DATASET'  ,'NEW CATEGORY SHORT'] - csv_lines.headers).empty?
      errors.add :csv, 'column headers does not match' and return false
    end

    csv_sheetcell_ids = csv_lines["ID"].collect {|s| s.to_i}
    errors.add :csv, 'IDs must be unique' and return false unless csv_sheetcell_ids.uniq!.nil?

    errors.add :csv, 'ID must not be empty' and return false if csv_lines["ID"].any?{|s| s.blank?}

    cat_sheetcell_ids = self.sheetcell_ids
    sheetcells_no_match = csv_sheetcell_ids - cat_sheetcell_ids
    unless sheetcells_no_match.empty?
      errors.add :csv, "sheetcell #{sheetcells_no_match} not found in category" and return false
    end
  end

  def split_sheetcells_category(csv_lines, user)
    pairs = csv_lines.reject{|l| l[4].blank?}.collect {|l| [l[0].to_i, l[4]]}
    updates_overview = Array.new
    altered_cats = Array.new
    pairs.each do |p|
      existing_cat = Category.where(datagroup_id: self.datagroup_id, short: p[1]).first
      if existing_cat
        if existing_cat == self
          updates_overview << [p[0], 'already', nil, nil]
        else
          Sheetcell.find(p[0]).update_attributes(category: existing_cat)
          altered_cats << existing_cat
          updates_overview << [p[0], 'added', existing_cat.id, existing_cat.short]
        end
      else
        new_category = Category.create(short: p[1], datagroup: self.datagroup)
        Sheetcell.find(p[0]).update_attributes(category: new_category)
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
