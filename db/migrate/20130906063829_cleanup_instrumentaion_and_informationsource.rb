class CleanupInstrumentaionAndInformationsource < ActiveRecord::Migration
  def up
    change_table :datacolumns, :bulk => true do |t|
      t.change :informationsource, :text
      t.change :instrumentation, :text
      t.string :acknowledge_unknown
    end
    Datacolumn.reset_column_information
    # move people names in informationsource field to the new created acknowledge_unknown field
    execute <<-SQL
      update datacolumns
      set acknowledge_unknown = replace(informationsource, 'These persons could be matched within the portal: ', '')
      where informationsource is not null and informationsource <> ''
    SQL
    execute <<-SQL
      update datacolumns
      set informationsource = null
      where informationsource is not null
    SQL

    # copy informationsource from datagroup to its datacolumns.
    Datagroup.where("informationsource is not null and informationsource <> ''").each do |dg|
      dg.datacolumns.update_all(informationsource: dg.informationsource)
    end

    # copy instrumentation from datagroup to its datacolumns.
    Datagroup.where("instrumentation is not null and instrumentation <> ''").each do |dg|
      dg.datacolumns.where("instrumentation is null or instrumentation = ''").update_all(instrumentation: dg.instrumentation)
    end

    remove_columns :datagroups, :instrumentation, :informationsource, :methodvaluetype
  end

  def down
    change_table :datagroups, :bulk => true do |t|
      t.text :instrumentation
      t.text :informationsource
      t.string :methodvaluetype
    end
    remove_column :datacolumns, :acknowledge_unknown
  end
end
