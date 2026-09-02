defmodule MercatoWeb.Admin.SettingsLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers
  alias Mercato.Accounts.Setting
  alias Mercato.Carts
  alias Mercato.Listings

  defp log_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  defp operator, do: admin_user() |> grant_permission("settings:update")

  defp open(conn), do: live(log_in(conn, operator()), ~p"/admin/settings")

  describe "access" do
    test "redirects a signed-out visitor to sign-in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/admin/settings")
    end

    test "redirects a signed-in user without admin:access away", %{conn: conn} do
      trader = generate(user())

      assert {:error, {:redirect, %{to: "/"}}} = live(log_in(conn, trader), ~p"/admin/settings")
    end

    test "lets an operator in", %{conn: conn} do
      {:ok, _view, html} = open(conn)

      assert html =~ "Marketplace settings"
    end
  end

  describe "the page" do
    test "gives each group of settings its own form", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      for section <- ~w(marketplace listings cart accounts) do
        assert has_element?(view, "#settings-#{section}-form")
      end
    end

    test "shows the platform defaults where nothing has been set", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      assert view |> element("#settings-marketplace-form") |> render() =~ "USD"
      assert view |> element("#settings-cart-form") |> render() =~ ~s(value="30")
      assert view |> element("#settings-listings-form") |> render() =~ "new, like_new, good, fair"
    end
  end

  describe "saving a group" do
    test "saves what the operator sets", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      assert view
             |> form("#settings-listings-form",
               listings: %{
                 "listing_conditions" => "mint, used",
                 "listing_image_types" => "image/png",
                 "listing_image_max_bytes" => "1000",
                 "listing_min_images" => "0",
                 "listing_max_images" => "4"
               }
             )
             |> render_submit() =~ "Listings settings saved"

      assert Listings.conditions() == ["mint", "used"]
      assert Listings.image_types() == ["image/png"]
      assert Listings.min_images() == 0
      assert Listings.max_images() == 4
    end

    test "leaves the groups the operator did not save alone", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      view
      |> form("#settings-cart-form", cart: %{"cart_retention_seconds" => "14"})
      |> render_submit()

      assert Carts.retention_seconds() == 14 * 24 * 60 * 60
      assert Setting.get(:currency) == "USD"
      assert Listings.conditions() == ["new", "like_new", "good", "fair"]
    end

    test "says so rather than saving a value the platform refuses", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      html =
        view
        |> form("#settings-cart-form", cart: %{"cart_retention_seconds" => "0"})
        |> render_submit()

      assert html =~ "must be greater than or equal to 1"
      assert Carts.retention_seconds() == 30 * 24 * 60 * 60
    end

    test "goes on editing the same row once one group has been saved", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      view
      |> form("#settings-marketplace-form", marketplace: %{"currency" => "GBP"})
      |> render_submit()

      view
      |> form("#settings-accounts-form", accounts: %{"handle_change_cooldown_days" => "7"})
      |> render_submit()

      assert Setting.get(:currency) == "GBP"
      assert Setting.get(:handle_change_cooldown_days) == 7
      assert Mercato.Repo.aggregate(Setting, :count) == 1
    end
  end
end
