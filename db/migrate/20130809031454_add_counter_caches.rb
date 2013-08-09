class AddCounterCaches < ActiveRecord::Migration
  def up
    add_column :datagroups, :datacolumns_count, :integer, :default => 0
    Datagroup.reset_column_information
    Datagroup.find_each do |dg|
      Datagroup.reset_counters(dg.id, :datacolumns)
    end
  end

  def down
    remove_column :datagroups, :datacolumns_count
  end
end
