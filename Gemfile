source 'http://rubygems.org'

gem 'rails', '3.2.11'
gem 'rake'
gem 'pg'
gem 'bundler'

gem 'haml'
gem 'authlogic'
gem 'acl9'
gem 'dynamic_form'
gem 'paperclip', '~> 3.0'
gem 'acts-as-taggable-on', '~> 2.2.2'
gem 'spreadsheet'
gem 'yaml_db'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'whenever', :require => false
gem 'activerecord-import'
gem 'newrelic_rpm'
gem 'pg_search'
group :test, :development do
  gem "test-unit", '2.4.8' #2.4.9 is incompatible to Rubymine's and Teamcity's way of running tests
                          # Issue is filed and update will fix this http://youtrack.jetbrains.com/issue/RUBY-11239
  gem 'foreman'
  # gem 'ruby-prof'
  gem 'libxml-ruby'
  gem 'rb-inotify'
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
end

# continous testing with guard
group :tools do
  gem 'guard'
  gem 'guard-test'
end