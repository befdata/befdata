class AddUserReceiveEmailsSwitch < ActiveRecord::Migration
  def change
    add_column :users, :receive_emails, :boolean, :default => false
  end
end
