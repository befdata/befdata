class CartDataset < ActiveRecord::Base
  belongs_to :cart
  belongs_to :dataset
end
