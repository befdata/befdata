class DatasetPaperproposal < ActiveRecord::Base
  belongs_to :paperproposal
  belongs_to :dataset
end
