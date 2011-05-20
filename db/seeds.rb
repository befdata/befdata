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
end