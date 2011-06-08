class UserAvatar < ActiveRecord::Base
  belongs_to :user

  # validates_presence_of :user_avatar_file_name, :message => "You have to select a file to be uploaded."

  has_attached_file :photo,
  :basename => "basename",
  :path => ":rails_root/user_avatars/:id_:filename",
  :default_url => ":rails_root/user_avatars/avatar-missing.png"
  :styles => {
    :thumb => "100x100#",
    :small => "150x150"
  }

  def basename
    return File.basename(self.file.original_filename, File.extname(self.file.original_filename))
  end
end
