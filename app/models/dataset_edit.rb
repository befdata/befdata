class DatasetEdit < ActiveRecord::Base
  belongs_to :dataset
  attr_accessible :description, :submitted

  validates_presence_of :dataset, :description
  #validate :only_one_unsubmitted_per_dataset

  def only_one_unsubmitted_per_dataset
    unsubmitted_edits = self.dataset.dataset_edits.where(:submitted => 'false')
    unless unsubmitted_edits.count == 0 || unsubmitted_edits.first == self
      errors.add(:submitted, 'only one unsubmitted edit per dataset allowed')
    end
  end

  def add_line!(line)
    unless self.description =~ /- #{line}/
      self.description ||= ''
      self.description = self.description + "\n - #{line}"
    end
    self.touch
    self.save
  end

end
