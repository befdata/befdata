class Cart < ActiveRecord::Base
  has_many :cart_contexts
  has_many :contexts, :through => :cart_contexts
end
