class CounterCacheDatafileFreeformatsToDatasets < ActiveRecord::Migration
  def up
    add_column :datasets, :datafiles_count, :integer, :default => 0
    add_column :datasets, :freeformats_count, :integer, :default => 0
    add_column :paperproposals, :freeformats_count, :integer, :default => 0

    Dataset.reset_column_information
    Paperproposal.reset_column_information

    Dataset.pluck(:id).each do |dt|
      Dataset.reset_counters dt, :datafiles , :freeformats
    end

    Paperproposal.pluck(:id).each do |pp|
      Paperproposal.reset_counters pp, :freeformats
    end
  end

  def down
    remove_columns :datasets, :datafiles_count, :freeformats_count
    remove_columns :paperproposals, :freeformats_count
  end
end
