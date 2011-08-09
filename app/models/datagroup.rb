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

  #TODO FERRET
  #acts_as_ferret :fields => [:title, :description, :comment]

  is_taggable :tags, :languages

  validates_presence_of :title, :description
  validates_uniqueness_of :title

  after_destroy :destroy_taggings
  before_destroy :check_for_system_datagroup

  scope :sheet_category_match, where(:type_id => Datagrouptype::SHEETCATEGORYMATCH)
  after_initialize :init

  # set the default value for system
  def init
    if(@new_record)
      self.type_id = Datagrouptype::DEFAULT
    end
  end

  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end

  def check_for_system_datagroup
    datagroup = self.reload
    if(datagroup.type_id != Datagrouptype::DEFAULT)
      raise Exception, "Cannot destroy a system datagroup"
      false
    end
  end

  def datacell_categories
    Category.all(:conditions => ["datagroup_id = ?" , self.id])
  end

  def datacell_categories_sql
    Category.all(:conditions => ["datagroup_id in (select sc.category_id
      from public.datacolumns dc
      inner join public.sheetcells sc
      on dc.Id = sc.datacolumn_id
      inner join public.categories c
      on sc.category_id = c.Id
      where dc.datagroup_id=" + self.id.to_s +
      " order by c.short)"
    ]
    )
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

  def self.find_sheet_category_match
    match = Datagroup.find_by_type_id(Datagrouptype::SHEETCATEGORYMATCH)

    unless match
      #TODO check if this has to do with bug #4809
      #@sophia this seems unnecessary why is it needed? As it is now there can not be two datagroups with the same title and therefor the creation silently fails!
      #In one migration and the fixtures there exists a "Category sheet match" datagroup ... is this intentionally?
      match = Datagroup.create!(:title => "Sheet category match",
                                :description => "Sheet category match",
                                :type_id => Datagrouptype::SHEETCATEGORYMATCH)
    end

    return match
  end

  def self.find_similar_by_title(title)

    # find suitable methods already available
    methods_available = Datagroup.find_all_by_title(title)
    #methods_available = [Datagroup.helper_method] unless methods_available
  end
end
