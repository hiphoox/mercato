defmodule Mercato.Accounts.UserRoleTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Accounts.{Role, UserRole}

  describe "identities" do
    test "assigning the same role to a user twice is rejected" do
      user = generate(user())
      role = Ash.Seed.seed!(Role, %{name: "trader_#{System.unique_integer([:positive])}"})

      Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})

      assert_raise Ash.Error.Invalid, fn ->
        Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})
      end
    end
  end

  describe "Mercato.Accounts.User.user_roles relationship" do
    test "loads the roles held by a user" do
      user = generate(user())
      role = Ash.Seed.seed!(Role, %{name: "trader_#{System.unique_integer([:positive])}"})
      Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})

      loaded = Ash.load!(user, :user_roles, authorize?: false)

      assert [%UserRole{role_id: role_id}] = loaded.user_roles
      assert role_id == role.id
    end
  end
end
