# Methodstep describes the method used in a particular measurement. It
# is a more general table than MeasurementsMethodstep and is called
# by the latter table. Thus, Methodstep can be reused, for example
# when the same method is used, but only the unit of measurement is
# changed. It contains information on
# * a source of information, like a literature citation or other manuals
# * the type of the value, which can be text, real, angle, category
# * title and lengthy description of the method
# * time latency, for which period of time is a measured value valid?
#
# Methodstep may have many MeasurementsMethodstep entries.

class Datagroup < ActiveRecord::Base

  has_many :datacolumns
  has_many :categories, :dependent => :destroy

  is_taggable :tags, :languages

  validates_presence_of :title, :description
  validates_uniqueness_of :title

  before_destroy :check_for_system_datagroup
  after_destroy :destroy_taggings


  after_initialize :init

  # set the default value for system
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
