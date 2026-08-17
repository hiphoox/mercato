defmodule Mercato.Accounts.RolePermissionTest do
  use Mercato.DataCase, async: true

  alias Mercato.Accounts.{Permission, Role, RolePermission}

  describe "identities" do
    test "granting the same permission to a role twice is rejected" do
      role = Ash.Seed.seed!(Role, %{name: "trader_#{System.unique_integer([:positive])}"})

      permission =
        Ash.Seed.seed!(Permission, %{name: "sell_#{System.unique_integer([:positive])}"})

      Ash.Seed.seed!(RolePermission, %{role_id: role.id, permission_id: permission.id})

      assert_raise Ash.Error.Invalid, fn ->
        Ash.Seed.seed!(RolePermission, %{role_id: role.id, permission_id: permission.id})
      end
    end
  end
end
