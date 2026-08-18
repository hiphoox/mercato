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
      role = Ash.Seed.seed!(Role, %{name: "role_#{System.unique_integer([:positive])}"})
      Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})

      loaded = Ash.load!(user, :user_roles, authorize?: false)

      role_ids = Enum.map(loaded.user_roles, & &1.role_id)

      # register_with_password already assigns the default `trader` role, so
      # a freshly generated user holds it alongside the one seeded above.
      assert role.id in role_ids
    end
  end
end
