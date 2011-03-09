class ChangeColumnNameMeasmethPersonroles < ActiveRecord::Migration
  def self.up
    rename_column :measmeths_personroles, :measurements_methodsteps_id, :measurements_methodstep_id
  end

  def self.down
    rename_column :measmeths_personroles, :measurements_methodstep_id, :measurements_methodsteps_id
  end
end
