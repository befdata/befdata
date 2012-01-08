require 'test_helper'

class DatagroupsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "show index of datagroups" do
    login_nadrowski

    get :index

    assert :success
  end
end