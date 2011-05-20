# START : HAX HAX HAX
# Load Rails environment in 'test' mode

RAILS_ENV = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
# Re-establish db connection for 'performance' mode
silence_warnings { Rails.env = "performance" }
ActiveRecord::Base.establish_connection
# STOP : HAX HAX HAX

require 'rails/test_help'
require 'rails/performance_test_help'
