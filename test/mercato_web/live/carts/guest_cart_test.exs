defmodule MercatoWeb.Carts.GuestCartTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias Mercato.Carts

  setup do
    %{seller: generate(user())}
  end

  describe "a visitor with no account" do
    test "reaches the cart rather than being sent to sign in", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/cart")

      assert has_element?(view, "#cart-empty")
    end

    test "gathers a listing from the browse grid", ctx do
      listing = offered_listing(ctx.seller)

      conn = get(ctx.conn, ~p"/")
      {:ok, browse, _html} = live(conn)
      browse |> element("#add-to-cart-#{listing.id}") |> render_click()

      {:ok, cart, _html} = live(conn, ~p"/cart")
      assert has_element?(cart, "#cart-group-#{ctx.seller.id}")
      assert render(cart) =~ listing.title
    end

    test "gathers a listing from a seller's profile", ctx do
      listing = offered_listing(ctx.seller)

      conn = get(ctx.conn, ~p"/users/#{ctx.seller.handle}")
      {:ok, profile, _html} = live(conn)
      profile |> element("#add-to-cart-#{listing.id}") |> render_click()

      {:ok, cart, _html} = live(conn, ~p"/cart")
      assert has_element?(cart, "#cart-group-#{ctx.seller.id}")
      assert render(cart) =~ listing.title
    end

    test "keeps what they gathered across a page they leave and come back to", ctx do
      listing = offered_listing(ctx.seller)

      conn = get(ctx.conn, ~p"/")
      {:ok, browse, _html} = live(conn)
      browse |> element("#add-to-cart-#{listing.id}") |> render_click()

      {:ok, again, _html} = live(conn, ~p"/")
      again |> element("#add-to-cart-#{listing.id}") |> render_click()

      {:ok, cart, _html} = live(conn, ~p"/cart")
      assert render(cart) =~ "2 items"
    end

    test "is offered the cart in the header, having somewhere to gather into", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#app-cart")
    end
  end

  describe "signing in" do
    test "finds what they gathered as a visitor waiting in their cart", ctx do
      listing = offered_listing(ctx.seller)

      buyer =
        generate(
          user(password: "correct-horse-battery", password_confirmation: "correct-horse-battery")
        )

      conn = get(ctx.conn, ~p"/")
      {:ok, browse, _html} = live(conn)
      browse |> element("#add-to-cart-#{listing.id}") |> render_click()

      {:ok, sign_in, _html} = live(conn, ~p"/sign-in")

      conn =
        sign_in
        |> form("#sign-in-user-password-sign-in-with-password", %{
          "user" => %{"email" => to_string(buyer.email), "password" => "correct-horse-battery"}
        })
        |> submit_form(conn)

      assert [line] = Carts.list_cart!(actor: buyer)
      assert line.listing_id == listing.id

      {:ok, cart, _html} = live(conn, ~p"/cart")
      assert render(cart) =~ listing.title
    end
  end
end
