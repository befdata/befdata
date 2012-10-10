require 'test_helper'

class UserLoginTest < ActionDispatch::IntegrationTest
  fixtures :all

  def setup
    @user = User.find_by_login('nadrowski')
  end

  test "login with wrong password should fail" do
    get data_path
    assert_response :success
    post user_session_path, {:user_session=>{:login=>@user.login, :password=>"wrong"}},{"HTTP_REFERER"=>data_path}
    assert_redirected_to data_path
    follow_redirect!
    assert_match /not/, flash[:error]
  end

  test "login with correct password should pass" do
    get data_path
    assert_response :success
    post(user_session_path, {:user_session=>{:login=>@user.login, :password=>"test"}},{"HTTP_REFERER"=> data_path})
    assert_redirected_to data_path
    follow_redirect!
    assert_equal "Login successful!", flash[:notice]
  end

  test "only logged-in users can visit forbidden page" do
    get current_cart_path
    assert_redirected_to root_path

    post(user_session_path, {:user_session=>{:login=>@user.login, :password=>"test"}})
    get current_cart_path
    assert_response :success
  end
  test "logout should redirect to welcome page" do
    post(user_session_path, {:user_session=>{:login=>@user.login, :password=>"test"}})
    get current_cart_url

    post logout_path, :method=> :delete
    assert_redirected_to root_url
    follow_redirect!
    assert_select "h2", /Welcome/
  end
  test "logged-in user can see 'Edit profile' link in his/her page" do
    # public visitor
    get user_path(User.first)
    assert_response :success
    assert_select "div#actions a", false, "public should not see link to edit profile"

    post(user_session_path, {:user_session=>{:login=>@user.login, :password=>"test"}})
    # visit others' profile page
    User.where(["login!=?",@user.login]).each do |u|
      get user_path(u)
      assert_response :success
      assert_select "div#actions a", false,"logged-in user should not see link to edit profile in others' page"
    end

    #visit own profile page
    get user_path(@user)
    assert_response :success
    assert_select "div#actions a", "Edit profile", "logged-in user should see link to edit profile in his/her own page"
  end
  test "Only logged-in user can visit profile and profile editing page" do
    get profile_path
    assert_redirected_to root_path
    assert_not_nil flash[:error], 'public should not be able to visit /profile page'

    get edit_profile_path
    assert_redirected_to root_path
    assert_not_nil flash[:error], 'public should not be able to visit /profile/edit page'

    post(user_session_path, {:user_session=>{:login=>@user.login, :password=>"test"}})

    get profile_path
    assert_success_no_error
    get edit_profile_path
    assert_success_no_error
  end
end
