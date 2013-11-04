## Datagroups define the type of data that has been recorded in terms of what was measured
## They can be reused across multiple "Datacolumn"s and "Dataset"s.
## A Helper (system) "Datagroup" is the default "Datagroup" when no specific measurement information is included in the "Dataworkbook".
##
## A "Category" must belong to a "Datagroup" and will be unique within that "Datagroup".
require 'csv'

class Datagroup < ActiveRecord::Base

  has_many :datacolumns
  has_many :categories, :dependent => :destroy
  has_many :datasets, :through => :datacolumns

  validates_presence_of :title, :description
  validates_uniqueness_of :title, :case_sensitive => false

  before_destroy :check_if_destroyable
  before_validation :fill_missing_description
  after_update { datasets.each(&:touch) }

  def check_if_destroyable
    errors.add :base, "'#{self.title}' is a system datagroup, thus can't be deleted" and return false if self.is_system_datagroup
    errors.add :base, "'#{self.title}' has associated datacolumns, thus can't be deleted" and return false if self.datacolumns(true).present?
    return true
  end

  def is_system_datagroup
    (self.type_id != Datagrouptype::DEFAULT)
  end

  def fill_missing_description
    self.description = self.title if self.description.blank?
  end

  def self.delete_orphan_datagroups
    # delete non-system orphan datagroups that has no associated datacolumns
    to_be_deleted = Datagroup.where(datacolumns_count: 0, type_id: Datagrouptype::DEFAULT)
    puts "#{to_be_deleted.count} datagroups is deleted at #{Time.now.utc}" unless to_be_deleted.empty?
    Datagroup.delete(to_be_deleted)
  end

  def update_and_merge_categories_with_csv (file, user)
    begin
      lines = CSV.read(file, CsvData::OPTS)
    rescue
      errors.add :file, 'can not be read' and return
    end
    return unless validate_categories_csv?(lines)

    merges = collect_merges(lines)
    updates = collect_updates(lines, user)
    # categories that are to be merged don't need to be updated
    merge_sources = merges.collect{|m| m["ID"].to_i}
    updates.reject! {|c| merge_sources.include?(c.id)}

    unless categories_remain_unique?(updates, merges)
      errors.add :categories, 'need to remain unique for datagroup' and return
    end

    # begin updating and merging
    # merging should be ahead of updating
    execute_merges(merges, user)
    execute_updates(updates)

    return {u: updates.length, m: merges.length}
  end

  def import_categories_with_csv(file)
    begin
      lines = CSV.read file, CsvData::OPTS
    rescue
      errors.add :file, "can't be read!" and return false
    end
    lines.headers.map {|h| h.downcase! } # so that headers can be case-insensitive

    return false unless validate_categories_csv_for_import?(lines)

    lines.each do |l|
      self.categories.create(short: l['short'], long: l['long'], description: l['description'])
    end

    return true
  end

  def self.search(q)
    if q
      where('title iLike :q OR description iLike :q', :q => "%#{q}%")
    else
      scoped
    end
  end

private

  def validate_categories_csv?(csv_lines)
    errors.add :csv, 'seems to be empty' and return false if csv_lines.empty?
    unless (['ID', 'SHORT', 'LONG', 'DESCRIPTION', 'MERGE ID'] - csv_lines.headers).empty?
      errors.add :csv, 'header does not match' and return false
    end
    errors.add :csv, 'IDs must be unique' and return false unless csv_lines["ID"].uniq!.nil?
    errors.add :csv, 'ID must not be empty' and return false if csv_lines["ID"].any?(&:blank?)
    errors.add :csv, 'SHORT must not be empty' and return false if csv_lines["SHORT"].any?(&:blank?)

    dg_cats_ids = self.category_ids

    cats_no_match = csv_lines["ID"].map(&:to_i) - dg_cats_ids
    unless cats_no_match.empty?
      errors.add :csv, "ID out of range: #{cats_no_match.to_sentence}" and return false
    end
    merge_ids_no_match = csv_lines["MERGE ID"].compact.map(&:to_i) - dg_cats_ids
    unless merge_ids_no_match.empty?
      errors.add :csv, "MERGE ID out of range: #{merge_ids_no_match.to_sentence}" and return false
    end

    merges = collect_merges(csv_lines)
    merge_source_ids = merges.map{|l| l["ID"]}
    merge_target_ids = merges.map{|l| l["MERGE ID"]}
    errors.add :csv, "Recursive merges are not allowed" and return false unless (merge_source_ids & merge_target_ids).empty?

    return true
  end

  def collect_merges(csv_lines)
    csv_lines.select {|l| l['MERGE ID'].present? && l['ID'] != l['MERGE ID']}
  end

  def collect_updates(lines, user)
    cats = self.categories.select([:id, :short, :long, :description, :comment])
    comment_string = "Updated via CVS by #{user.lastname}, #{Time.now.to_s}."
    changes = []

    lines.each do |l|
      c = cats.detect{|c| c.id == l["ID"].to_i}
      if c.short != l['SHORT'] || c.long != l['LONG'] || c.description != l['DESCRIPTION']
        c.short = l['SHORT']
        c.long = l['LONG']
        c.description = l['DESCRIPTION']
        c.comment = "#{c.comment} #{comment_string}".strip
        changes << c
      end
    end
    return changes
  end

  def categories_remain_unique?(updates, merges)
    changed_categories = updates.collect {|u| u.id} | merges.collect{|m| m['ID'].to_i}
    short_of_unchanged_categories = self.categories.where("id NOT IN (?)", changed_categories).pluck('lower(short)')
    all_shorts = updates.collect{|u| u.short.downcase} + short_of_unchanged_categories
    all_shorts.uniq!.nil? ? true : false
  end

  def execute_merges(merge_pairs, user)
    merge_pairs.each do |mp|
      source_cat = Category.find mp["ID"]
      target_cat = Category.find mp["MERGE ID"]
      Category.merge(source_cat, target_cat, user)
    end
  end

  def execute_updates(updates)
    ActiveRecord::Base.transaction do
      updates.each { |c| c.save }
    end
  end

  def validate_categories_csv_for_import?(csv_lines)
    errors.add :file, 'is empty' and return false if csv_lines.empty?
    unless (['short', 'long', 'description'] - csv_lines.headers).empty?
      errors.add :csv, 'header does not match' and return false
    end
    errors.add :base, "category short can't be empty" and return false if csv_lines["short"].any?{|s| s.blank?}

    short = csv_lines['short'].collect {|s| s.downcase}
    existing_short = self.categories.pluck('lower(short)')
    duplicated_shorts = (short + existing_short).group_by {|c| c}.select {|k,v| v.size > 1}.keys
    unless duplicated_shorts.empty?
      errors.add :base, 'Duplicated categories found: ' + "#{duplicated_shorts.join(',')}" and return false
    end

    return true
  end
end
