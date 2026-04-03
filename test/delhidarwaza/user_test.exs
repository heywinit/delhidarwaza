defmodule DelhiDarwaza.UserTest do
  use ExUnit.Case, async: true

  alias DelhiDarwaza.User

  describe "new/3" do
    test "creates a user with the given parameters" do
      user = User.new("user_1", "trader", "trader@example.com")

      assert user.id == "user_1"
      assert user.username == "trader"
      assert user.email == "trader@example.com"
      refute is_nil(user.created_at)
    end
  end
end
