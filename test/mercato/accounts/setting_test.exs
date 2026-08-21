defmodule Mercato.Accounts.SettingTest do
  use Mercato.DataCase, async: true

  alias Mercato.Accounts
  alias Mercato.Accounts.Setting

  describe "current_settings/1" do
    test "returns nothing when no setting row has been seeded" do
      assert {:ok, nil} = Accounts.current_settings(authorize?: false, not_found_error?: false)
    end

    test "returns the seeded settings row" do
      Setting
      |> Ash.Changeset.for_create(:create, %{handle_change_cooldown_days: 7})
      |> Ash.create!(authorize?: false)

      assert {:ok, %Setting{handle_change_cooldown_days: 7}} =
               Accounts.current_settings(authorize?: false, not_found_error?: false)
    end
  end

  describe "handle_change_cooldown_days/0" do
    test "defaults to 30 when no setting row exists" do
      assert Setting.handle_change_cooldown_days() == 30
    end

    test "reflects the value of a seeded setting row" do
      Setting
      |> Ash.Changeset.for_create(:create, %{handle_change_cooldown_days: 7})
      |> Ash.create!(authorize?: false)

      assert Setting.handle_change_cooldown_days() == 7
    end
  end
end
