class CreateVocabs < ActiveRecord::Migration
  def up
    create_table :vocabs do |t|
      t.string :term
      t.timestamps
    end
    add_column :datacolumns, :term_id, :integer
  end

  def down
    drop_table :vocabs
    remove_columns :datacolumns, :term_id
  end
end
