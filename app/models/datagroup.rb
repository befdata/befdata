## The Datagroup class represents the Datagroup table.
##
## Datagroups define the type of data that has been recorded in terms of what was measured and how it was measured.
##
## Datagroups can be used across "Dataset"s. A "Datacolumn" can only have one "Datagroup", whilst a "Datagroup" can contain one or more "Datatype"s.
## A "Category" must belong to a "Datagroup".

class Datagroup < ActiveRecord::Base

  has_many :datacolumns
  has_many :categories, :dependent => :destroy

  is_taggable :tags, :languages

  validates_presence_of :title, :description
  validates_uniqueness_of :title

  before_destroy :check_for_system_datagroup
  after_destroy :destroy_taggings

  after_initialize :init

  # set the default value for datagroup
  def init
    if(@new_record)
      self.type_id = Datagrouptype::DEFAULT
    end
  end

  def destroy_taggings
    self.taggings.destroy_all
  end

  def check_for_system_datagroup
      raise Exception, "Cannot destroy a system datagroup" if is_system_datagroup
  end

  def is_system_datagroup
    self.reload
    return (self.type_id != Datagrouptype::DEFAULT)
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

    return helper
  end

end
