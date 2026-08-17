defmodule Mercato.Accounts.RoleTest do
  use Mercato.DataCase, async: true

  alias Mercato.Accounts.Role

  describe "create" do
    test "creates a role with a name and description" do
      role =
        Ash.create!(
          Role,
          %{name: "trader_#{System.unique_integer([:positive])}", description: "Buy + sell"},
          authorize?: false
        )

      assert role.description == "Buy + sell"
    end

    test "upserts on name instead of raising a uniqueness error" do
      name = "trader_#{System.unique_integer([:positive])}"

      first = Ash.create!(Role, %{name: name, description: "Original"}, authorize?: false)
      second = Ash.create!(Role, %{name: name, description: "Updated"}, authorize?: false)

      assert first.id == second.id
      assert second.description == "Updated"
    end
  end
end
