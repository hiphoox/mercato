defmodule Mercato.Accounts.PermissionTest do
  use Mercato.DataCase, async: true

  alias Mercato.Accounts.Permission

  describe "create" do
    test "creates a permission with a name and description" do
      permission =
        Ash.create!(
          Permission,
          %{
            name: "manage_listings_#{System.unique_integer([:positive])}",
            description: "Manage listings"
          },
          authorize?: false
        )

      assert permission.description == "Manage listings"
    end

    test "upserts on name instead of raising a uniqueness error" do
      name = "manage_listings_#{System.unique_integer([:positive])}"

      first = Ash.create!(Permission, %{name: name, description: "Original"}, authorize?: false)
      second = Ash.create!(Permission, %{name: name, description: "Updated"}, authorize?: false)

      assert first.id == second.id
      assert second.description == "Updated"
    end
  end

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
