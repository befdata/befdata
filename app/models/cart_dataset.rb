## Links "Cart"s to "Dataset"s and maps to the "cart_datasets" table.
class CartDataset < ActiveRecord::Base
  belongs_to :cart
  belongs_to :dataset
end
