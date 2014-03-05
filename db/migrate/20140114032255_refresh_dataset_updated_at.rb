class RefreshDatasetUpdatedAt < ActiveRecord::Migration
  def up
    execute <<-SQL
      update datasets
         set updated_at = tmp.last_update
        from
        (
          select datasets.id, GREATEST(datasets.updated_at, max(freeformats.updated_at)) as last_update
            from datasets left join freeformats
              on freeformats.freeformattable_id = datasets.id
             AND freeformats.freeformattable_type = 'Dataset'
        group by datasets.id
        ) tmp
      where datasets.id = tmp.id
        and tmp.last_update > datasets.updated_at
    SQL
  end
end
