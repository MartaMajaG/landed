require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  test "routes task index" do
    assert_routing "/tasks", controller: "tasks", action: "index"
  end

  test "routes task show" do
    assert_routing "/tasks/1", controller: "tasks", action: "show", id: "1"
  end
end
