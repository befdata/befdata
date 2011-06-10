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

  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end


  def datacell_categories
    dcs = self.datacolumns.collect{|dh| dh.sheetcells}.flatten
    dcs = dcs.select{|dc| dc.datatype.name == "category"}
    cats = []
    unless dcs.blank?
      cats = dcs.collect{|dc| dc.category}.uniq
      cats = cats.sort{|x,y| x.short <=> y.short}
    end
    cats
  end

  def datacell_categories_sql
    Category.all(:conditions => ["id in (select sc.category_id
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
    helper = Datagroup.find_all_by_title("Helper")

    unless helper
      helper = Datagroup.create(:title => "Helper",
                                :description => "Helper Method for something")
    end

    return helper
  end


end
