require "test_helper"

class UserChecklistItemsControllerTest < ActionDispatch::IntegrationTest
  test "should get update" do
    get user_checklist_items_update_url
    assert_response :success
  end
end
