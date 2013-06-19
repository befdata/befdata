# This file contains the DatasetPaperproposal class definition, organising the usage of Dataset instances
# by Paperproposal instances. Paperproposals organise the access rights to data.

# The class DatasetPaperproposal links Dataset instances to Paperproposal instances. It is used
# for determining access to the primary data from the Sheetcell instances and to Freeformatfile instances.
#
# DatsetPaperproposals do not store access rights directly, which is done by the acl9 gem and the
# Role class. They contain information if a Dataset is of main or side aspect for the conclusions derived
# from analysing data according to the Paperproposal.
class DatasetPaperproposal < ActiveRecord::Base
  belongs_to :paperproposal
  belongs_to :dataset

  validates :aspect, :presence => true, :inclusion => { :in => %w{main side} }
end
