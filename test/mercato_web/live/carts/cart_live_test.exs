defmodule MercatoWeb.Carts.CartLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers
  alias Mercato.Carts
  alias Mercato.Listings.Listing.Slug

  defp log_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  setup %{conn: conn} do
    buyer = generate(user())

    %{conn: log_in(conn, buyer), buyer: buyer, seller: generate(user())}
  end

  describe "access" do
    test "lets a visitor with no account in, a cart being gathered before it is bought" do
      {:ok, view, _html} = live(Phoenix.ConnTest.build_conn(), ~p"/cart")

      assert has_element?(view, "#cart")
    end

    test "lets a signed-in buyer in", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#cart")
    end
  end

  describe "an empty cart" do
    test "explains how to start rather than reading as an error", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#cart-empty")
      refute has_element?(view, "#cart-total")
    end

    test "is what somebody else's lines read as", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: generate(user()))

      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#cart-empty")
    end
  end

  describe "what has been gathered" do
    setup ctx do
      listing = offered_listing(ctx.seller, price: 1500, quantity: 4)
      {:ok, cart_line} = Carts.add_to_cart(listing.id, %{quantity: 2}, actor: ctx.buyer)

      Map.merge(ctx, %{listing: listing, cart_line: cart_line})
    end

    test "reads as one group per seller", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#cart-group-#{ctx.seller.id}")
      assert has_element?(view, "#cart-line-#{ctx.cart_line.id}")
    end

    test "opens the listing behind a line", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(
               view,
               ~s(#cart-line-#{ctx.cart_line.id} a[href="/listings/#{Slug.slug(ctx.listing)}"])
             )
    end

    test "shows what the seller is asking now, times how many are wanted", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert view |> element("#cart-line-#{ctx.cart_line.id} [data-role=line-total]") |> render() =~
               "$30.00"
    end

    test "totals the group and the whole cart", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert view |> element("#cart-group-#{ctx.seller.id} [data-role=group-total]") |> render() =~
               "$30.00"

      assert view |> element("#cart-total") |> render() =~ "$30.00"
    end

    test "offers a checkout per seller, since one order covers one seller", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(
               view,
               ~s(#checkout-#{ctx.seller.id}[href="/checkout?seller=#{ctx.seller.id}"])
             )
    end

    test "says nothing about a split when there is only one seller", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      refute has_element?(view, "#cart-split-note")
    end

    test "says the cart is split when more than one seller is in it", ctx do
      other = offered_listing(generate(user()))
      {:ok, _} = Carts.add_to_cart(other.id, %{}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#cart-split-note")
    end
  end

  describe "changing what is in the cart" do
    setup ctx do
      listing = offered_listing(ctx.seller, price: 1500, quantity: 4)
      {:ok, cart_line} = Carts.add_to_cart(listing.id, %{quantity: 2}, actor: ctx.buyer)

      Map.merge(ctx, %{listing: listing, cart_line: cart_line})
    end

    test "raising the quantity moves the totals with it", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      view |> element("#qty-#{ctx.cart_line.id}-increase") |> render_click()

      assert view |> element("#cart-total") |> render() =~ "$45.00"
    end

    test "lowering the quantity moves the totals with it", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      view |> element("#qty-#{ctx.cart_line.id}-decrease") |> render_click()

      assert view |> element("#cart-total") |> render() =~ "$15.00"
    end

    test "removing the last line empties the cart", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      view |> element("#remove-#{ctx.cart_line.id}") |> render_click()

      refute has_element?(view, "#cart-line-#{ctx.cart_line.id}")
      assert has_element?(view, "#cart-empty")
    end

    test "a line of one cannot be stepped down to none", ctx do
      {:ok, _} = Carts.set_cart_quantity(ctx.cart_line, %{quantity: 1}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#qty-#{ctx.cart_line.id}-decrease[disabled]")
    end

    test "a line cannot be stepped past what the seller has", ctx do
      {:ok, _} = Carts.set_cart_quantity(ctx.cart_line, %{quantity: 4}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#qty-#{ctx.cart_line.id}-increase[disabled]")
    end
  end

  describe "a one-of-a-kind listing" do
    test "says so instead of offering a stepper there is nothing to step", ctx do
      listing = offered_listing(ctx.seller, quantity: 1)
      {:ok, cart_line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#cart-line-#{cart_line.id} [data-role=one-of-a-kind]")
      refute has_element?(view, "#qty-#{cart_line.id}")
    end
  end

  describe "a line that can no longer be bought" do
    setup ctx do
      gone = offered_listing(ctx.seller, price: 4000)
      kept = offered_listing(ctx.seller, price: 1500)
      {:ok, gone_line} = Carts.add_to_cart(gone.id, %{}, actor: ctx.buyer)
      {:ok, kept_line} = Carts.add_to_cart(kept.id, %{}, actor: ctx.buyer)

      Mercato.Listings.pause_listing!(gone, actor: ctx.seller)

      Map.merge(ctx, %{gone: gone, gone_line: gone_line, kept_line: kept_line})
    end

    test "still names what the buyer gathered, so they know which one went", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert view |> element("#cart-line-#{ctx.gone_line.id}") |> render() =~ ctx.gone.title
      assert has_element?(view, "#cart-line-#{ctx.gone_line.id} [data-role=unavailable]")
    end

    test "offers nothing to step, there being nothing to buy", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      refute has_element?(view, "#qty-#{ctx.gone_line.id}")
      assert has_element?(view, "#remove-#{ctx.gone_line.id}")
    end

    test "counts for nothing in the group's total or the cart's", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert view |> element("#cart-group-#{ctx.seller.id} [data-role=group-total]") |> render() =~
               "$15.00"

      assert view |> element("#cart-total") |> render() =~ "$15.00"
    end

    test "stops the group being checked out while it is there", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#checkout-#{ctx.seller.id}[disabled]")
      assert has_element?(view, "#cart-group-#{ctx.seller.id} [data-role=blocked]")
    end

    test "gives the group back its checkout once the buyer removes it", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      view |> element("#remove-#{ctx.gone_line.id}") |> render_click()

      refute has_element?(view, "#cart-line-#{ctx.gone_line.id}")
      refute has_element?(view, "#checkout-#{ctx.seller.id}[disabled]")
    end

    test "leaves another seller's group checkable out", ctx do
      other_seller = generate(user())
      other = offered_listing(other_seller)
      {:ok, _} = Carts.add_to_cart(other.id, %{}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/cart")

      assert has_element?(view, "#checkout-#{ctx.seller.id}[disabled]")
      refute has_element?(view, "#checkout-#{other_seller.id}[disabled]")
    end
  end
end
