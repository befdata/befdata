class CreateDatasetTagsView < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE OR REPLACE view dataset_tags AS
        (
          select taggable_id as dataset_id, tag_id
          from taggings
          where taggable_type = 'Dataset'
        union
          select distinct d.dataset_id, g.tag_id
          from taggings g join datacolumns d
          on g.taggable_id = d.id
          where g.taggable_type = 'Datacolumn'
        );
    SQL
  end

  def down
    execute <<-SQL
      drop view dataset_tags;
    SQL
  end
end
