class RemoveUnusedTags < ActiveRecord::Migration
  def self.up
    all_tags = ActsAsTaggableOn::Tag.all.map(&:id)
    used_tags = ActsAsTaggableOn::Tagging.all.map(&:tag_id)
    ActsAsTaggableOn::Tag.find(all_tags-used_tags).each(&:destroy)
  end

  def self.down
    #irreversible
  end
end
