defmodule Mercato.Accounts.UserPolicyTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Accounts.{Role, User, UserRole}

  defp assign_role(user, role_name) do
    role = Ash.Seed.seed!(Role, %{name: role_name})
    Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})
    user
  end

  describe "update policy" do
    test "a user can update their own record" do
      user = generate(user())

      assert Ash.can?({user, :update_handle}, user)
    end

    test "a user cannot update another user's record" do
      user = generate(user())
      other = generate(user())

      refute Ash.can?({user, :update_handle}, other)
    end

    test "an admin can update another user's record" do
      user = generate(user())
      admin = generate(user()) |> assign_role("admin")

      assert Ash.can?({user, :update_handle}, admin)
    end
  end

  describe "visible_email calculation" do
    test "resolves to the real email for the user's own record" do
      user = generate(user())

      loaded = Ash.load!(user, :visible_email, actor: user)

      assert to_string(loaded.visible_email) == to_string(user.email)
    end

    test "resolves to nil for another user's record" do
      user = generate(user())
      other = generate(user())

      loaded = Ash.load!(user, :visible_email, actor: other)

      refute loaded.visible_email
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
