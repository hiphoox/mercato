defmodule Mercato.Accounts.RolePermissionTest do
  use Mercato.DataCase, async: true

  alias Mercato.Accounts.{Permission, Role, RolePermission}

  describe "create" do
    test "grants a permission to a role" do
      role = Ash.Seed.seed!(Role, %{name: "trader_#{System.unique_integer([:positive])}"})

      permission =
        Ash.Seed.seed!(Permission, %{name: "sell_#{System.unique_integer([:positive])}"})

      grant =
        Ash.create!(RolePermission, %{role_id: role.id, permission_id: permission.id},
          authorize?: false
        )

      assert grant.role_id == role.id
      assert grant.permission_id == permission.id
    end

    test "upserts instead of raising when the grant already exists" do
      role = Ash.Seed.seed!(Role, %{name: "trader_#{System.unique_integer([:positive])}"})

      permission =
        Ash.Seed.seed!(Permission, %{name: "sell_#{System.unique_integer([:positive])}"})

      first =
        Ash.create!(RolePermission, %{role_id: role.id, permission_id: permission.id},
          authorize?: false
        )

      second =
        Ash.create!(RolePermission, %{role_id: role.id, permission_id: permission.id},
          authorize?: false
        )

      assert first.role_id == second.role_id
      assert first.permission_id == second.permission_id
    end
  end

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
