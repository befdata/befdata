class Observation
  # This is only to demonstrate how a "virtual" observation model could work
  # the method below is in no what performant enough to be actually used :)
  def self.find_for_dataset_and_row_number(dataset, row_number)
    dataset.sheetcells.find_all_by_row_number(row_number)
  end
end