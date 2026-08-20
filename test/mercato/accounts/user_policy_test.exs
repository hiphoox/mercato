defmodule Mercato.Accounts.UserPolicyTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Accounts
  alias Mercato.Accounts.{Permission, Role, RolePermission, User, UserRole}

  defp assign_role(user, role_name) do
    role = Ash.Seed.seed!(Role, %{name: role_name})
    Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})
    user
  end

  defp grant_permission(user, permission_name) do
    role = Ash.Seed.seed!(Role, %{name: "role_#{System.unique_integer([:positive])}"})
    permission = Ash.Seed.seed!(Permission, %{name: permission_name})
    Ash.Seed.seed!(RolePermission, %{role_id: role.id, permission_id: permission.id})
    Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})
    user
  end

  describe "update policy" do
    test "a user can update their own record" do
      user = generate(user())

      assert Accounts.can_update_handle?(user, user, "new_handle")
    end

    test "a user cannot update another user's record" do
      user = generate(user())
      other = generate(user())

      refute Accounts.can_update_handle?(other, user, "new_handle")
    end

    test "an actor holding the user:update permission can update another user's record" do
      user = generate(user())
      manager = generate(user()) |> grant_permission("user:update")

      assert Accounts.can_update_handle?(manager, user, "new_handle")
    end

    test "an actor whose role has no permissions cannot update another user's record" do
      user = generate(user())
      bystander = generate(user()) |> assign_role("role_#{System.unique_integer([:positive])}")

      refute Accounts.can_update_handle?(bystander, user, "new_handle")
    end
  end

  describe "change_status" do
    test "an actor holding the user:update permission can change another user's status" do
      user = generate(user())
      manager = generate(user()) |> grant_permission("user:update")

      assert Accounts.can_change_status?(manager, user, :banned)
    end

    test "a user cannot change their own status" do
      user = generate(user())

      refute Accounts.can_change_status?(user, user, :banned)
    end

    test "an actor without the user:update permission cannot change another user's status" do
      user = generate(user())
      other = generate(user())

      refute Accounts.can_change_status?(other, user, :banned)
    end

    test "an actor holding the user:update permission banning a user persists the new status" do
      user = generate(user())
      manager = generate(user()) |> grant_permission("user:update")

      assert {:ok, banned} = Accounts.change_status(user, :banned, %{}, actor: manager)
      assert banned.status == :banned
    end

    test "a self-attempt to change status raises Forbidden" do
      user = generate(user())

      assert_raise Ash.Error.Forbidden, fn ->
        Accounts.change_status!(user, :banned, %{}, actor: user)
      end
    end
  end

  describe "public fields" do
    test "a user can read another user's public handle field" do
      user = generate(user())
      other = generate(user())

      loaded = Ash.get!(User, user.id, actor: other)

      assert loaded.handle == user.handle
    end
  end
end
