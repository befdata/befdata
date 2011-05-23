require 'performance_test_helper'

# Profiling results for each test method are written to tmp/performance.
class PolymorphicTest < ActionDispatch::PerformanceTest
  def test_acl9_polymorphic
    last_dataset = Dataset.last
    last_user = User.last
    last_user.has_role? :owner, last_dataset
  end

  def test_acl9_collect_all_datasets_for_first_user
    last_dataset = Dataset.last
    first_user = User.first
    first_user.has_role? :owner, last_dataset
    all_datasets = first_user.role_objects.select{|rob| rob.authorizable_type=="Dataset"}.map{|c| c.authorizable}
  end

  def test_acl9_collect_all_datasets_for_first_user_second_way
    first_user = User.first

    all_dataset = Dataset.all.collect{|d| d.accepts_role? :owner, User.first}
  end

  def test_collect_column_from_dataset
    dataset = Dataset.first
    datacolumn = Datacolumn.find(:all, :conditions => [ "dataset_id = ?", dataset.id ],
                                      :order => 'columnnr ASC')
  end

  def test_collect_sheetcells_from_datacolumn
    dataset = Dataset.first
    datacolumns = Datacolumn.find(:all, :conditions => [ "dataset_id = ?", dataset.id ],
                                      :order => 'columnnr ASC')
    sheetcells = Sheetcell.find(:all, :conditions => [ "datacolumn_id = ?", datacolumns.first.id ], :include => :value)
  end
  
end
