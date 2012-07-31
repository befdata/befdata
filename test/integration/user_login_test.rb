require 'test_helper'

class UserLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create(login: "test",
                        email: "test@example.com",
                        firstname: "testuser",
                        password: "12345",
                        password_confirmation: "12345",
                        lastname: "testuser")
  end

  test "login failed before success" do
    get root_path
    assert_response :success
    post user_session_path, user_session: {login: @user.login, password: "wrong" }
    assert_redirected_to root_path
    follow_redirect!
    assert_match /not/, flash[:error]
    post user_session_path, user_session: {login: @user.login, password: @user.password }
    assert_redirected_to root_path
    follow_redirect!
    assert_equal "Login successful!", flash[:notice]
    assert_select "h2", /Welcome/
  end
end
