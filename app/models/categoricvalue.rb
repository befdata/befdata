class Categoricvalue < ActiveRecord::Base
    def verbose
    "#{short} -- #{long} -- #{description}"
  end
end
