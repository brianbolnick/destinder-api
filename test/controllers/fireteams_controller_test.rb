require 'test_helper'

class FireteamsControllerTest < ActionDispatch::IntegrationTest
  test "should get validate_user" do
    get fireteams_validate_user_url
    assert_response :success
  end

  test "should get create" do
    get fireteams_create_url
    assert_response :success
  end

  test "should get show" do
    get fireteams_show_url
    assert_response :success
  end

  test "should get update" do
    get fireteams_update_url
    assert_response :success
  end

  test "should get destroy" do
    get fireteams_destroy_url
    assert_response :success
  end

end
