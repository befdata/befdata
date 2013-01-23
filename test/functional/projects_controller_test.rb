require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  setup :activate_authlogic
  test "should get show project" do
    get :show, {:id => Project.first.id}
    assert_success_no_error
  end
  test 'not show link to create new project for public' do
    get :index
    assert_select "a[href=?]", "/projects/new", false
  end
  test "not show link to create new project for regular user" do
    login_user("Phdstudentnutrientcycling")
    get :index
    assert_select "a[href=?]", "/projects/new", false
  end
  test 'show link to create new project for admin' do
    login_nadrowski
    assert User.find_by_login("nadrowski").has_role?(:admin)
    get :index
    assert_select "a[href=?]", "/projects/new"
  end
  test "public user should not be able to create new project" do
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  test "regular user should not be able to create new project" do
    login_user("Phdstudentnutrientcycling")
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  test "admin should be able to create new project" do
    login_nadrowski
    assert User.find_by_login("nadrowski").has_role?(:admin)
    get :new
    assert_success_no_error
  end
  test "project can't be edited by public" do
    get :edit, :id => Project.first
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  test "project can't be edited by non-admin" do
    login_user("Phdstudentnutrientcycling")
    get :edit, :id => Project.first
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  test "project can be edited by admin" do
    login_nadrowski
    assert User.find_by_login("nadrowski").has_role?(:admin)
    get :edit, :id => Project.first
    assert_success_no_error
  end
  test "don't show link to delete a project for project in use" do
    login_nadrowski
    get :show, :id => Project.first
    assert_select "a[href=?]", "/projects/#{Project.first}", false
    assert_select "a[data-method=?]","delete",false
  end
  test "show link to delete a project for obsolete project" do
    login_nadrowski
    p = Project.create({name: "test", shortname: "test"})
    get :show, :id => p
    assert_success_no_error
    assert_select "a[href=?]", "/projects/#{p.id}", true, "link to delete a obsolete project should be seen"
    assert_select "a[data-method=?]","delete", true, "link to delete a obsolete project should be seen"
  end
  test "update membership process should honest user's input" do
    p = Project.find(2)
    # basic meta params hash
    project = {name: p.name, shortname: p.shortname}
    # this project now has one pi(id=3) and one phd(id=5). no other roles
    assert_equal  [3], p.pi.map(&:id), "project(id=2) should has user(id=3) as pi"
    assert_equal  [5], p.get_user_with_role(:"phd student").map(&:id), "project(id=2) should has user(id=5) as phd"
    # membership params hash
    # now i am going to delete the pi, set users(id=5,1) as student, user(id=3) as phd
    roles = [{type: "phd student", value: ["3"]},
             {type: "student", value: ["1","5"]}]
    # no matter what the member was before, the final membership should honest params from user inputs
    login_nadrowski
    post :update, :id => p, :project => project, :roles => roles
    assert_success_no_error
    p.reload
    assert_empty p.pi, "there should not be pi for this project after updating"
    assert_equal  [3], p.get_user_with_role(:"phd student").map(&:id), "updating phd failed"
    assert_empty [1,5] - p.get_user_with_role(:student).map(&:id), "updating student failed"
  end
end
