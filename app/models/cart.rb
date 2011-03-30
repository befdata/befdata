class Cart < ActiveRecord::Base
  has_many :cart_datasets
  has_many :datasets, :through => :cart_datasets
end
