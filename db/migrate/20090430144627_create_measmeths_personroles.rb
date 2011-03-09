class CreateMeasmethsPersonroles < ActiveRecord::Migration
  def self.up
    create_table :measmeths_personroles do |t|
      t.integer :measurements_methodsteps_id
      t.integer :person_role_id
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :measmeths_personroles
  end
end
