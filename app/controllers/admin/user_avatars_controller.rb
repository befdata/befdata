class Admin::UserAvatarsController < Admin::AdminController
  active_scaffold :user_avatar do |config|
    config.create.multipart = true
    config.update.multipart = true
  end
end