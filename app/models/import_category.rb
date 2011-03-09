class ImportCategory < ActiveRecord::Base

  belongs_to :measurements_methodstep
  belongs_to :categoricvalue, :dependent => :destroy

  validates_presence_of :measurements_methodstep, :categoricvalue

end
