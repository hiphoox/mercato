defmodule Mercato.Accounts.SettingTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Accounts
  alias Mercato.Accounts.Setting

  describe "current_settings/1" do
    test "returns nothing when no setting row has been seeded" do
      assert {:ok, nil} = Accounts.current_settings(authorize?: false, not_found_error?: false)
    end

    test "returns the seeded settings row" do
      Accounts.create_settings!(%{handle_change_cooldown_days: 7}, authorize?: false)

      assert {:ok, %Setting{handle_change_cooldown_days: 7}} =
               Accounts.current_settings(authorize?: false, not_found_error?: false)
    end
  end

  describe "get/1" do
    test "falls back to the platform default when no row has been seeded" do
      assert Setting.get(:handle_change_cooldown_days) == 30
      assert Setting.get(:cart_retention_seconds) == 2_592_000
      assert Setting.get(:currency) == "USD"
      assert Setting.get(:listing_conditions) == ["new", "like_new", "good", "fair"]
      assert Setting.get(:listing_image_types) == ["image/jpeg", "image/png", "image/webp"]
      assert Setting.get(:listing_image_max_bytes) == 5_242_880
      assert Setting.get(:listing_min_images) == 1
      assert Setting.get(:listing_max_images) == 10
    end

    test "reads what the operator set" do
      Accounts.create_settings!(
        %{
          handle_change_cooldown_days: 7,
          cart_retention_seconds: 5,
          currency: "EUR",
          listing_conditions: ["roadworthy"],
          listing_image_types: ["image/png"],
          listing_image_max_bytes: 100,
          listing_min_images: 0,
          listing_max_images: 3
        },
        authorize?: false
      )

      assert Setting.get(:handle_change_cooldown_days) == 7
      assert Setting.get(:cart_retention_seconds) == 5
      assert Setting.get(:currency) == "EUR"
      assert Setting.get(:listing_conditions) == ["roadworthy"]
      assert Setting.get(:listing_image_types) == ["image/png"]
      assert Setting.get(:listing_image_max_bytes) == 100
      assert Setting.get(:listing_min_images) == 0
      assert Setting.get(:listing_max_images) == 3
    end
  end

  describe "who may change them" do
    test "an operator holding settings:update may edit the row" do
      admin = admin_user() |> grant_permission("settings:update")
      settings = Accounts.create_settings!(%{}, authorize?: false)

      assert %Setting{cart_retention_seconds: 14} =
               Accounts.update_settings!(settings, %{cart_retention_seconds: 14}, actor: admin)
    end

    test "an ordinary account may not" do
      buyer = generate(user())
      settings = Accounts.create_settings!(%{}, authorize?: false)

      assert {:error, %Ash.Error.Forbidden{}} =
               Accounts.update_settings(settings, %{cart_retention_seconds: 14}, actor: buyer)
    end

    test "anyone may read them, since a signed-out visitor browses on them" do
      assert {:ok, _settings} = Accounts.current_settings(not_found_error?: false)
    end
  end
end
