class AddPaperproposalAttributesToFreeformat < ActiveRecord::Migration
  def change
    add_column :freeformats, :is_essential, :boolean, :default => false
    add_column :freeformats, :uri, :string
  end
end
