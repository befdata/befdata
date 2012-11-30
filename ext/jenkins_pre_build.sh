#!/bin/bash -e
rvm use ruby-1.9.3@befdata
cp config/database.yml.dist config/database.yml
bundle install 
bundle exec rake db:migrate
bundle exec rake
