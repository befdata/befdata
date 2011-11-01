## The Cart class maps to the "Carts" table. An instance of a Cart is created when a "User" selects a "Dataset"
## that they would like to include in a "Paperproposal", if a Cart does not already exist for that "User".
## A Cart is linked to a "User" by a cookie stored on the User's computer.
##
## A Cart can have one or more "Dataset"s; they are linked using the "CartDataset" class.
class Cart < ActiveRecord::Base
  has_many :cart_datasets
  has_many :datasets, :through => :cart_datasets
end
