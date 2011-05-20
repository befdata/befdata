# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)


if Rails.env="performance"
  i = 0
  p "Creating 5000 users and datasets"
  while i < 5000
    dataset = Dataset.new
    person = User.new
    person.login = "test#{i}"
    person.email = "test#{i}@email.de"
    person.crypted_password = "#{i}"
    person.password_salt = "#{i}"
    person.persistence_token = "#{i}"
    person.single_access_token = "#{i}"
    person.perishable_token = "#{i}"
    person.lastname = "Test#{i}"
    person.firstname = "Test#{i}"
    dataset.save(:validate => false)
    person.save(:validate => false)
    person.has_role! :owner, dataset
    p i = i + 1
  end

  person = User.first
  i = 0
  p "Creating 5000 roles for first user to all datasets"
  while i < 4000
    dataset = Dataset.find(i+1)
    person.has_role! :owner, dataset if dataset
    p i = i + 1
  end

  p "Creating the data to test the sheet cell performance"
  dataset = Dataset.first

  i=0
  p "Creating 8000 observations"
  while i < 8000
    observation = Observation.create(:rownr => i + 1)
    p i = i + 1
  end
  p "Finished"

  i=0
  p "Creating 20 columns in the dataset"
  while i < 20
    p "Creating column #{i + 1}"
    data_group = Datagroup.create(:title => "Test#{i}",
                                  :description => "Test#{i}")
    # the first 5 columns will be text
    datatype = "text"
    case i
      when 1,2,3,4,5
        datatype = "text"
        importvalue = "Test#{i}"
      when 6,7,8,9,10
        datatype = "category"
        importvalue ="Test#{i}"
      when 11,12,13,14,15
        datatype = "number"
        importvalue =i
      else
        datatype = "date"
        importvalue ="2009-11-08"
    end
    data_column = Datacolumn.create(:datagroup => data_group,
                                     :dataset => dataset,
                                     :columnheader => "Test#{i}",
                                     :comment => "Test#{i}",
                                     :columnnr => i + 1,
                                     :definition => "Test#{i}",
                                     :import_data_type => datatype)

    #create a sheet cell for each of the observations
    j=0
    while j < 8000
      # find the observation
      observation = Observation.find(j+1)
      sheet_cell = Sheetcell.create(:datacolumn => data_column,
                                    :observation => observation,
                                    :import_value => importvalue)

      case i
        when 1,2,3,4,5
          value = Textvalue.create(:text => "Test#{j}")
        when 6,7,8,9,10
          value = Categoricvalue.create(:short => "Test#{j}",
                                        :long => "Test#{j}",
                                        :description => "Test#{j}",
                                        :comment => "automatically generated")
        when 11,12,13,14,15
          value = Numericvalue.create(:number => 12)
        else
          value = Datetimevalue.create(:date => "2009-11-09")
      end

      sheet_cell.update_attributes(:value => value,
                                   :comment => "test match")
      j = j + 1
    end
    p "Finished column #{i + 1}"
    i = i + 1
  end
  p "Finished adding the data to test the sheet cell performance"

end