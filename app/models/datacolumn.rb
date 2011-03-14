class Datacolumn < ActiveRecord::Base

  is_taggable :tags, :languages
  after_destroy :destroy_taggings

  acts_as_authorization_object :subject_class_name => 'User'


  belongs_to :datagroup
  belongs_to :dataset

  has_many :sheetcells, :dependent => :destroy

  validates_presence_of :datagroup_id, :dataset_id, :columnheader, :columnnr, :definition
  validates_uniqueness_of :columnheader, :columnnr, :scope => :dataset_id

  def destroy_taggings
    logger.debug "in destroy taggings"
    self.taggings.destroy_all
  end

end
