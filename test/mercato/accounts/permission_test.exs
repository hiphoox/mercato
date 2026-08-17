defmodule Mercato.Accounts.PermissionTest do
  use Mercato.DataCase, async: true

  alias Mercato.Accounts.Permission

  describe "identities" do
    test "rejects a duplicate name" do
      name = "manage_listings_#{System.unique_integer([:positive])}"

      Ash.Seed.seed!(Permission, %{name: name, description: "First"})

      assert_raise Ash.Error.Invalid, fn ->
        Ash.Seed.seed!(Permission, %{name: name, description: "Second"})
      end
    end
  end
end
