class AddCommentAndInitialTitleToPaperproposal < ActiveRecord::Migration
  def self.up
    add_column :paperproposals, :initial_title, :string
    add_column :paperproposals, :comment, :text
  end

  def self.down
    remove_column :paperproposals, :comment
    remove_column :paperproposals, :initial_title
  end
end
