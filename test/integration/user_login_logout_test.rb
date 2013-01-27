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
end
