# Whenever provides a nice dsl to write cronjobs.
# Of course this is only available on Platforms which support cron (i.e. NOT on Windows)
# On deployment the cronjobs have to be set up by executing whenever from the applications directory
# ------------------------------------------------------
# whenever --write-crontab --set 'environment=production'
# ------------------------------------------------------


# For cron scheduled tasks to play along with rvm on ubuntu it is necessary to uncomment
# # If not running interactively, don't do anything
# [ -z "$PS1" ] && return
# in ~/.bashrc
#
# Tasks will fail with stuff like "no such file to load -- rubygems (LoadError)"

set :output, 'log/whenever_cron_errors.log'

every 3.minutes do
  runner 'ExportedFile.regenerate_downloads_for_outdated_files'
end

every 1.day, :at => '0:10 am' do
  runner "Paperproposal.revoke_old_download_rights"
end

# cleanup orphan datagroups and categories
#every :day, :at => '1:00 am' do
#  rake 'cleanup:all'
#end
