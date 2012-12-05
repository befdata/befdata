## The Datagroup class models the Datagroup table.
##
## Datagroups define the type of data that has been recorded in terms of what was measured, how it was measured and any information source or reference used.
## They can be reused across multiple "Datacolumn"s and "Dataset"s.
## A Helper (system) "Datagroup" is the default "Datagroup" when no specific measurement information is included in the "Dataworkbook".
##
## A "Datagroup" can contain one or more "Datatype"s.
## A "Category" must belong to a "Datagroup" and will be unique within that "Datagroup".
require 'csv'

class Datagroup < ActiveRecord::Base

  has_many :datacolumns
  has_many :categories, :dependent => :destroy
  has_many :datasets, :through => :datacolumns

  acts_as_taggable

  validates_presence_of :title, :description
  validates_uniqueness_of :title

  before_destroy :check_if_destroyable
  after_destroy :destroy_taggings

  after_initialize :init
  after_update { datasets.map(&:touch) }
  # set the default value for datagroup
  def init
    if(@new_record)
      self.type_id = Datagrouptype::DEFAULT
    end
  end

  def destroy_taggings
    self.taggings.destroy_all
  end

  def check_if_destroyable
    unless !self.is_system_datagroup &&
        (self.datacolumns.empty? || (self.datacolumns.count == 1 && self.datacolumns.first.destroyed?))
      false
    end
  end

  def is_system_datagroup
    self.reload
    (self.type_id != Datagrouptype::DEFAULT)
  end

  def abbr_method
    text = "#{self.title}: #{self.description}"
    if text.length > 200
      [text[0..200], " ... (continued)"].join
    else
      text
    end
  end

  def helper_method
    helper = Datagroup.find_all_by_type_id(Datagrouptype::HELPER)

    unless helper
      helper = Datagroup.create(:title => "Helper",
                                :description => "Helper Method for something",
                                :type_id => Datagrouptype::HELPER)
    end
    helper
  end

  def update_categories_with_csv (file, user)
    begin
      lines = CSV.read file
    rescue
      errors.add :file, 'can not be read' and return false
    end
    lines = validate_and_reduce_categories_csv(lines)
    return if !lines || !errors.blank?

    cats = Category.find lines.collect{|l| l[0]}
    comment_string = "Updated via CVS by #{user.lastname}, #{Time.now.to_s}."
    changes = []

    lines.each do |l|
      c = cats.detect{|c| c.id == l[0].to_i}
      if c.short != l[1] || c.long != l[2] || c.description != l[3]
        changes << c
        c.short = l[1]
        c.long = l[2]
        c.description = l[3]
        c.comment = "#{c.comment} #{comment_string}".strip
      end
    end

    unless categories_remain_unique?(changes)
      errors.add :categories, 'need to remain unique for datagroup' and return false
    end

    merges = collect_merges(lines)
    validate_merges(merges, lines)
    return if !errors.blank?

    merge_sources = merges.collect{|m| m[0]}
    changes.reject! {|c| merge_sources.include?(c.id)}

    changes.each {|c| c.save}
    execute_merges(merges,user)

    update_overview = Hash.new
    changes.each do |c|
      update_overview[c.id] = 'u'
    end
    merges.each do |m|
      update_overview[m[1]] = update_overview[m[1]].to_s + 'm'
    end
    update_overview
  end

private

  def validate_and_reduce_categories_csv (csv_lines)
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

    csv_cats_ids = csv_lines.collect{|l| l[0].to_i}

    unless csv_cats_ids.uniq!.nil?
      errors.add :csv, 'IDs must be unique' and return false
    end

    dg_cats_ids = self.categories.collect{|c| c.id}
    cats_no_match = csv_cats_ids - dg_cats_ids
    unless cats_no_match.empty?
      errors.add :csv, "category #{cats_no_match} not matching the categories of this datagroup" and return false
    end

    csv_lines.each do |l|
      if l[0].blank?
        errors.add :csv, 'ID must not be empty' and return false
      end
      if l[1].blank?
        errors.add :csv, 'SHORT must not be empty' and return false
      end
    end

    csv_lines
  end

  def categories_remain_unique? (changed_categories)
    unchanged_categories = self.categories.select(:short).where("id NOT IN (?)", changed_categories.collect{|c| c.id})
    all_shorts = unchanged_categories.collect{|c| c.short} + changed_categories.collect{|c| c.short}
    all_shorts.uniq! == nil ? true : false
  end

  def collect_merges (csv_lines)
    csv_lines.reject {|l| l[4].blank?}.collect {|l| [l[0].to_i, l[4].to_i]}
  end

  def validate_merges(merge_pairs, csv_lines)
    csv_ids = csv_lines.collect {|l| l[0].to_i}
    merge_source_ids = merge_pairs.collect {|mp| mp[0]}
    merge_target_ids = merge_pairs.collect {|mp| mp[1]}

    unless (merge_target_ids - csv_ids).empty?
      errors.add :categories, 'can not merge with categories which are not present'
    end

    unless (merge_target_ids & merge_source_ids).empty?
      errors.add :categories, 'recursive merges are not allowed'
    end
  end

  def execute_merges(merge_pairs, user)
    merge_pairs.each do |mp|
      source_cat = Category.find mp[0]
      target_cat = Category.find mp[1]

      cells = source_cat.sheetcells
      cells.each do |cell|
        cell.category = target_cat
        cell.save
      end
      comment_string = "Merged #{source_cat.id} via CVS by #{user.lastname}, #{Time.now.to_s}."
      target_cat.comment = "#{target_cat.comment} #{comment_string}".strip
      target_cat.save
      source_cat.destroy
    end
  end

end
