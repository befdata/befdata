# This is a view-based model
# The view is defined in migration file: 20131116163151_create_dataset_tags_view.rb
# More info about view-based model can be found in Chapter 11 in book 'Enterprise Rails'.

class DatasetTag < ActiveRecord::Base
  belongs_to :dataset
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'

  def self.tag_counts
    ActsAsTaggableOn::Tag.joins('left join dataset_tags on tags.id = dataset_tags.tag_id')
                         .select('tags.*, count(dataset_id) as count')
                         .group('tags.id')
                         .order('lower(tags.name)')
  end
end
