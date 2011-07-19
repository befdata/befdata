class Settings::SettingsController < ApplicationController
  layout 'admin'

  skip_before_filter :deny_access_to_all
end