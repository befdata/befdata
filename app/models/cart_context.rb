class CartContext < ActiveRecord::Base
  belongs_to :cart
  belongs_to :context
end
