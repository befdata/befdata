class AddIndexes < ActiveRecord::Migration
  def self.up
    # author_paperproposals table
    add_index :author_paperproposals, [:user_id, :paperproposal_id]

    # cart_datasets table
    add_index :cart_datasets, [:cart_id]
    add_index :cart_datasets, [:dataset_id]

    # datacolumns
    add_index :datacolumns, [:datagroup_id, :dataset_id]

    # dataset_paperproposals
    add_index :dataset_paperproposals, [:dataset_id, :paperproposal_id]

    # filevalues
    add_index :filevalues, [:paperproposal_id]

    # observation_sheetcells
    add_index :observation_sheetcells, [:observation_id, :sheetcell_id]

    # paperproposal_votes
    add_index :paperproposal_votes, [:paperproposal_id]
    add_index :paperproposal_votes, [:user_id]

    # paperproposals
    add_index :paperproposals, [:author_id]
    add_index :paperproposals, [:corresponding_id]

    # sheetcells
    add_index :sheetcells, [:datacolumn_id]
    add_index :sheetcells, [:observation_id]
    add_index :sheetcells, [:value_id, :value_type]

    # taggings
    add_index :taggings, [:tag_id]
    add_index :taggings, [:taggable_id, :taggable_type]
  end

  def self.down
    # author_paperproposals table
    remove_index :author_paperproposals, [:user_id, :paperproposal_id]

    # cart_datasets table
    remove_index :cart_datasets, [:cart_id]
    remove_index :cart_datasets, [:dataset_id]

    # datacolumns
    remove_index :datacolumns, [:datagroup_id, :dataset_id]

    # datset_paperproposals
    remove_index :datset_paperproposals, [:dataset_id, :paperproposal_id]

    # filevalues
    remove_index :filevalues, [:paperproposal_id]

    # observation_sheetcells
    remove_index :observation_sheetcells, [:observation_id, :sheetcell_id]

    # paperproposal_votes
    remove_index :paperproposal_votes, [:paperproposal_id]
    remove_index :paperproposal_votes, [:user_id]

    # paperproposals
    remove_index :paperproposals, [:author_id]
    remove_index :paperproposals, [:corresponding_id]

    # sheetcells
    remove_index :sheetcells, [:datacolumn_id]
    remove_index :sheetcells, [:observation_id]
    remove_index :sheetcells, [:value_id, :value_type]

    # taggings
    remove_index :taggings, [:tag_id]
    remove_index :taggings, [:taggable_id, :taggable_type]
  end
end
