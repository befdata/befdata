class MakeFreeformatsPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :freeformats, :freeformattable_id, :integer
    add_column :freeformats, :freeformattable_type, :string
    make_old_dataset_freefromats_polymorpic
    convert_paperproposal_datafiles_to_freeformats
    remove_column :freeformats, :dataset_id
    remove_column :freeformats, :paperproposal_id
    remove_column :datafiles, :paperproposal_id
  end

  def self.down
    add_column :freeformats, :dataset_id, :integer
    add_column :freeformats, :paperproposal_id, :integer
    add_column :datafiles, :paperproposal_id, :integer
    convert_polymorphic_freeformats_back
    remove_column :freeformats, :freeformattable_id
    remove_column :freeformats, :freeformattable_type
  end

  def self.make_old_dataset_freefromats_polymorpic
    Freeformat.select{|ff| !ff.dataset_id.blank?}.each do |ff|
      ff.update_attribute :freeformattable_id, ff.dataset_id
      ff.update_attribute :freeformattable_type, "Dataset"
    end
  end

  def self.convert_paperproposal_datafiles_to_freeformats
    Paperproposal.all.each do |pp|
      pp.datafiles.each do |df|
        ff = Freeformat.new :file => File.new(df.file.path)
        ff.save false
        ff.update_attribute :freeformattable_id, df.paperproposal_id
        ff.update_attribute :freeformattable_type, "Paperproposal"
        df.destroy
      end
    end
  end

  def self.convert_polymorphic_freeformats_back
    # care about the freeformats with datasets
    Freeformat.select{|ff| ff.freeformattable_type == "Dataset"}.each do |ff|
      ff.update_attribute :dataset_id, ff.freeformattable_id
    end

    # care about the datafiles on paperproposals
    Freeformat.select{|ff| ff.freeformattable_type == "Paperproposal"}.each do |ff|
      df = Datafile.new :file => File.new(ff.file.path)
      df.save false
      df.update_attribute :paperproposal_id, ff.freeformattable_id
      ff.destroy
    end
  end
end
