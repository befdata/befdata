require 'test_helper'

class Settings::DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test "normal users can show own dataset" do
    pending "i could not figure out how to set the active scaffold constraints"
    #normal_owner = (dataset_owners & non_admin_users).first
    #owned_dataset = find_users_objects_by_role(normal_owner, "owner","Dataset").first
    #login_user normal_owner.login

    #@active_scaffold_constraints = {:id => owned_dataset.id}

    #get :index, :id => owned_dataset.id, :constraints => {:id => owned_dataset.id},:id => owned_dataset.id
    #assert_response :success
    #assert_template 'list'
  end

  test "normal users can update details of own dataset" do
    pending "i could not figure out how to set the active scaffold constraints"
    #normal_owner = (dataset_owners & non_admin_users).first
    #login_user normal_owner.login
    #owned_dataset = find_user_datasets_with_role(normal_owner, :owner).first

    #ActiveScaffold.active_scaffold_session_storage[:constraints][:id] = owned_dataset.id

    #get :edit, :id => owned_dataset.id
    #assert_response :success
    #assert_template 'update'
  end
end