module UsersHelper
  def all_users_names_and_ids_for_select
    User.order(:lastname).collect {|person| [person.to_s, person.id]}
  end
end
