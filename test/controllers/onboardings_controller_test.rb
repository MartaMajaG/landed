require "test_helper"

class OnboardingsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get onboardings_show_url
    assert_response :success
  end

  test "should get update" do
    get onboardings_update_url
    assert_response :success
  end
end
