xml.instruct!
xml.users(:version => 1) do
  @users.each do |u|
    xml.user do
      xml.id u.id
      xml.firstname u.firstname
      xml.lastname u.lastname
      xml.salutation  u.salutation
      xml.email u.email
    end
  end
end