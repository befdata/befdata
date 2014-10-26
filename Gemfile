source 'https://rubygems.org'

gem 'rails', "3.2.19"
gem 'pg'
gem 'haml'
gem 'authlogic'
gem 'acl9', '~> 0.12.1'
gem 'dynamic_form'
gem "paperclip", "~> 3.5.4"
gem "acts-as-taggable-on", "~> 2.4.1"
gem 'spreadsheet'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'whenever', :require => false
gem 'activerecord-import'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'will_paginate'

# elasticsearch
gem 'elasticsearch'
gem 'elasticsearch-rails'
gem 'elasticsearch-model'

# group :production do
  # gem 'newrelic_rpm'
  # gem 'party_foul'   
# end

# gem 'rack-mini-profiler', :group => :development

group :test, :development do
  gem "test-unit"
  gem 'foreman'
  # gem 'ruby-prof'
  gem 'libxml-ruby'
  gem 'rb-inotify'
  gem 'thin'
  # gem 'debugger'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'coveralls', require: false       #Coverage reporting badge
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
end

group :tools do
  gem 'guard'
  gem 'guard-test'
  gem 'hpricot' 
  gem 'ruby_parser', '>= 3.1.2'
end
