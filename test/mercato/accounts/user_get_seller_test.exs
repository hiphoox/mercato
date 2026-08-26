defmodule Mercato.Accounts.UserGetSellerTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Accounts

  describe "get_seller" do
    test "finds an account by the handle its public profile is addressed by" do
      user = generate(user())

      assert {:ok, found} = Accounts.get_seller(user.handle)
      assert found.id == user.id
    end

    test "finds it without an actor, since the profile is public" do
      user = generate(user())

      assert {:ok, _found} = Accounts.get_seller(user.handle, actor: nil)
    end

    test "does not find a handle nobody holds" do
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Accounts.get_seller("nobody_at_all")
    end

    test "does not find a banned account" do
      user = generate(user())
      admin = admin_user() |> grant_permission("user:update")
      Accounts.change_status!(user, :banned, actor: admin)

      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Accounts.get_seller(user.handle)
    end

    test "still finds a restricted account, which is limited rather than shut out" do
      user = generate(user())
      admin = admin_user() |> grant_permission("user:update")
      Accounts.change_status!(user, :restricted, actor: admin)

      assert {:ok, _found} = Accounts.get_seller(user.handle)
    end

    test "does not find a deleted account" do
      user = generate(user())
      Accounts.delete_account!(user, actor: user)

      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Accounts.get_seller(user.handle)
    end
  end

  describe "inserted_at" do
    test "stamps when the account was opened, so a profile can say how long it has been here" do
      user = generate(user())

      assert %DateTime{} = user.inserted_at
      assert DateTime.diff(DateTime.utc_now(), user.inserted_at, :second) < 5
    end
  end
end
