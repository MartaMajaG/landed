require "test_helper"

class UserChecklistItemsControllerTest < ActionDispatch::IntegrationTest
  test "routes checklist item update" do
    assert_routing(
      { method: "patch", path: "/user_checklist_items/1" },
      controller: "user_checklist_items",
      action: "update",
      id: "1"
    )
  end

  test "routes checklist item unlock" do
    assert_routing(
      { method: "patch", path: "/user_checklist_items/1/unlock" },
      controller: "user_checklist_items",
      action: "unlock",
      id: "1"
    )
  end
end
