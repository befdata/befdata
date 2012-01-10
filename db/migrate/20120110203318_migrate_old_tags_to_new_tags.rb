class MigrateOldTagsToNewTags < ActiveRecord::Migration
  def self.up
    OldTag.all.each do |old_tag|
      p "Migrating #{old_tag.name}"

      old_taggings = OldTagging.find_all_by_tag_id(old_tag.id)

      new_tag = ActsAsTaggableOn::Tag.new(:name => old_tag.name)
      new_tag.save

      old_taggings.each do |old_tagging|
        new_tagging = ActsAsTaggableOn::Tagging.new(:taggable_id => old_tagging.taggable_id,
                                                    :taggable_type => old_tagging.taggable_type,
                                                    :context => 'tags')
        new_tag.taggings << new_tagging
        new_tag.save
      end

    end
  end

  def self.down
  end
end
