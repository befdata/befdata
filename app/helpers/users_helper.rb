module UsersHelper
  def all_users_names_and_ids_for_select
    User.select('id, salutation, firstname, lastname').order('lower(firstname), lower(lastname)').collect {|u| [u.to_s, u.id]}
  end
end
