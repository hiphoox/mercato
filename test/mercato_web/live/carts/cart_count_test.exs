defmodule MercatoWeb.Carts.CartCountTest do
  @moduledoc """
  What the header's cart control counts, wherever the buyer is standing.
  """
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers
  alias Mercato.Carts

  defp log_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  setup %{conn: conn} do
    buyer = generate(user())

    %{conn: log_in(conn, buyer), buyer: buyer, seller: generate(user())}
  end

  test "counts the buyer's lines on a page that is not the cart", ctx do
    listing = offered_listing(ctx.seller)
    {:ok, _} = Carts.add_to_cart(listing.id, %{quantity: 2}, actor: ctx.buyer)

    {:ok, view, _html} = live(ctx.conn, ~p"/users/me/profile")

    assert has_element?(view, "#app-cart-count", "2")
  end

  test "says nothing until something is gathered", ctx do
    {:ok, view, _html} = live(ctx.conn, ~p"/users/me/profile")

    refute has_element?(view, "#app-cart-count")
  end

  test "moves as the buyer gathers, without them leaving the page", ctx do
    listing = offered_listing(ctx.seller)
    {:ok, browse, _html} = live(ctx.conn, ~p"/")

    refute has_element?(browse, "#app-cart-count")

    browse |> element("#add-to-cart-#{listing.id}") |> render_click()

    assert has_element?(browse, "#app-cart-count", "1")
  end

  test "moves as the buyer clears a line out of the cart", ctx do
    listing = offered_listing(ctx.seller)
    {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

    {:ok, view, _html} = live(ctx.conn, ~p"/cart")
    assert has_element?(view, "#app-cart-count", "1")

    view |> element("#remove-#{line.id}") |> render_click()

    refute has_element?(view, "#app-cart-count")
  end

  test "counts nothing for a line that can no longer be bought", ctx do
    listing = offered_listing(ctx.seller)
    {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
    Mercato.Listings.pause_listing!(listing, actor: ctx.seller)

    {:ok, view, _html} = live(ctx.conn, ~p"/users/me/profile")

    refute has_element?(view, "#app-cart-count")
  end

  # Drawn on every page, so it must not clear a lapsed line out from under the
  # buyer: the cart is what sweeps, and what it swept is news it has to break.
  test "leaves a lapsed line where it is rather than sweeping it in passing", ctx do
    put_setting(:cart_retention_seconds, 60)
    listing = offered_listing(ctx.seller)
    {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
    age_cart_line(line, 120)

    {:ok, view, _html} = live(ctx.conn, ~p"/users/me/profile")

    refute has_element?(view, "#app-cart-count")

    assert {:error, {:live_redirect, %{flash: flash}}} =
             live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

    assert flash["error"] =~ "sat in your cart too long"
  end

  test "counts a visitor's cart, an account being no part of gathering one", ctx do
    listing = offered_listing(ctx.seller)
    conn = Phoenix.ConnTest.build_conn() |> get(~p"/")
    {:ok, browse, _html} = live(conn)

    browse |> element("#add-to-cart-#{listing.id}") |> render_click()

    {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

    assert has_element?(view, "#app-cart-count", "1")
  end
end
