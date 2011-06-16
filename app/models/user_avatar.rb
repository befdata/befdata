class UserAvatar < ActiveRecord::Base

  has_many :user
  validates_presence_of :avatar_file_name, :message => "You have to select a file to be uploaded."
  validates_attachment_content_type :avatar, :content_type => ['image/jpeg','image/png']


  has_attached_file :avatar,
  #:basename => "basename",
  :url => "/images/user_avatars/:basename_:style.:extension",
  :path => ":rails_root/public/images/user_avatars/:basename_:style.:extension",
  :default_style => :small,
  :styles => {
    :small => "50x50#",
    :medium => "80x80",
    :large => "150x150"
  }

#  def basename
#    return File.basename(self.file.original_filename, File.extname(self.file.original_filename))
#  end

end
