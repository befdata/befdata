class SetAllContextsVisible < ActiveRecord::Migration
  def self.up
    ## mind that this will replace even existing values!
    Context.find(:all).each do |c|
      c.update_attribute :visible_for_public, true
    end
  end

  def self.down
  end
end
