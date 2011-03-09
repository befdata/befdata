class CreateDataProposals < ActiveRecord::Migration
  def self.up
    create_table :data_proposals do |t|
      t.integer :author_id
      t.date_time :envisaged_date
      t.string :envisaged_journal
      t.string :title
      t.string :abstract
      t.timestamps
    end
  end

  def self.down
    drop_table :data_proposals
  end
end
