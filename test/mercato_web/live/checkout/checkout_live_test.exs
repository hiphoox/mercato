defmodule MercatoWeb.Checkout.CheckoutLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers
  alias Mercato.Carts
  alias Mercato.Payments

  defp log_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  setup %{conn: conn} do
    buyer = generate(user())

    %{conn: log_in(conn, buyer), buyer: buyer, seller: generate(user())}
  end

  describe "the group a checkout is for" do
    test "opens on the seller group the buyer asked to pay for", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

      assert has_element?(view, "#checkout")
    end

    test "sends the buyer back where a seller names no group of theirs", ctx do
      other_seller = generate(user())

      assert {:error, {:live_redirect, %{to: "/cart"}}} =
               live(ctx.conn, ~p"/checkout?#{[seller: other_seller.id]}")
    end

    test "says a deleted listing went rather than that it was never gathered", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      :ok = Mercato.Listings.delete_listing(listing, actor: ctx.seller)

      assert {:error, {:live_redirect, %{to: "/cart", flash: flash}}} =
               live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

      assert flash["error"] =~ "no longer available"
    end

    test "says a lapsed group lapsed rather than that it went", ctx do
      put_setting(:cart_retention_seconds, 60)
      listing = offered_listing(ctx.seller)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
      age_cart_line(line, 120)

      assert {:error, {:live_redirect, %{to: "/cart", flash: flash}}} =
               live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

      assert flash["error"] =~ "sat in your cart too long"
    end

    test "sends the buyer back where the seller is not one at all", ctx do
      assert {:error, {:live_redirect, %{to: "/cart"}}} =
               live(ctx.conn, ~p"/checkout?#{[seller: Ash.UUID.generate()]}")
    end

    test "sends the buyer back where no seller is named", ctx do
      assert {:error, {:live_redirect, %{to: "/cart"}}} = live(ctx.conn, ~p"/checkout")
    end

    test "is one seller's and not another's, so no combined checkout exists", ctx do
      other_seller = generate(user())
      mine = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(mine.id, %{}, actor: ctx.buyer)

      {:ok, _view, _html} = live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

      assert {:error, {:live_redirect, %{to: "/cart"}}} =
               live(ctx.conn, ~p"/checkout?#{[seller: other_seller.id]}")
    end
  end

  describe "a visitor with no account" do
    test "reaches the checkout for what they gathered rather than a sign-in form", ctx do
      listing = offered_listing(ctx.seller)
      conn = Phoenix.ConnTest.build_conn() |> get(~p"/")
      {:ok, browse, _html} = live(conn)
      browse |> element("#add-to-cart-#{listing.id}") |> render_click()

      {:ok, view, _html} = live(conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

      assert has_element?(view, "#checkout")
    end

    test "is sent back to the cart where they gathered nothing from that seller", ctx do
      conn = Phoenix.ConnTest.build_conn() |> get(~p"/")

      assert {:error, {:live_redirect, %{to: "/cart"}}} =
               live(conn, ~p"/checkout?#{[seller: ctx.seller.id]}")
    end
  end

  describe "a group holding something unbuyable" do
    test "is refused, the cart's disabled button not being the only way in", ctx do
      gone = offered_listing(ctx.seller)
      kept = offered_listing(ctx.seller)
      for l <- [gone, kept], do: {:ok, _} = Carts.add_to_cart(l.id, %{}, actor: ctx.buyer)

      Mercato.Listings.pause_listing!(gone, actor: ctx.seller)

      assert {:error, {:live_redirect, %{to: "/cart"}}} =
               live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")
    end
  end

  describe "what is being bought, from whom, and at what total" do
    test "names every line in the group", ctx do
      one = offered_listing(ctx.seller, title: "Walnut sideboard", price: 24_000)
      two = offered_listing(ctx.seller, title: "Brass reading lamp", price: 6_000)
      for l <- [one, two], do: {:ok, _} = Carts.add_to_cart(l.id, %{}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

      assert has_element?(view, "#checkout", "Walnut sideboard")
      assert has_element?(view, "#checkout", "Brass reading lamp")
    end

    test "says who the buyer is buying from", ctx do
      seller = generate(user(first_name: "Marta", last_name: "Ribeiro"))
      listing = offered_listing(seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/checkout?#{[seller: seller.id]}")

      assert has_element?(view, "[data-role=seller-name]", "Marta Ribeiro")
    end

    test "states the total the group comes to", ctx do
      listing = offered_listing(ctx.seller, price: 24_000)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
      {:ok, _} = Carts.set_cart_quantity(line, %{quantity: 2}, actor: ctx.buyer)

      {:ok, group} = Carts.checkout_group(ctx.seller.id, actor: ctx.buyer)
      {:ok, view, _html} = live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

      assert has_element?(view, "#checkout-summary [data-role=total]", group.total)
    end

    test "is a review and not a second cart, so nothing here is editable", ctx do
      listing = offered_listing(ctx.seller, quantity: 5)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

      refute has_element?(view, "#qty-#{line.id}")
      refute has_element?(view, "#remove-#{line.id}")
    end

    test "carries the buyer-protection promise the cart made", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")

      assert has_element?(view, "#checkout-protection", "confirm the delivery arrived")
    end
  end

  describe "what the total is made of" do
    defp fee(attrs), do: Payments.add_buyer_fee!(attrs, authorize?: false)

    defp checkout(ctx, price) do
      listing = offered_listing(ctx.seller, price: price)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      {:ok, view, _html} = live(ctx.conn, ~p"/checkout?#{[seller: ctx.seller.id]}")
      view
    end

    test "gives the items a line of their own rather than one opaque number", ctx do
      view = checkout(ctx, 24_000)

      assert has_element?(view, "#checkout-summary", "Items")
      assert has_element?(view, "#checkout-summary", "$240.00")
    end

    test "gives a flat fee a line under the operator's own wording", ctx do
      fee(%{name: "Protection fee", kind: :flat, amount: 199})

      view = checkout(ctx, 24_000)

      assert has_element?(view, "#checkout-summary", "Protection fee")
      assert has_element?(view, "#checkout-summary", "$1.99")
    end

    test "gives a percentage fee a line of what it comes to on this sale", ctx do
      fee(%{name: "Service fee", kind: :percentage, rate_bp: 500})

      view = checkout(ctx, 24_000)

      assert has_element?(view, "#checkout-summary", "Service fee")
      assert has_element?(view, "#checkout-summary", "$12.00")
    end

    test "totals the items and every fee, which is what the buyer pays", ctx do
      fee(%{name: "Protection fee", kind: :flat, amount: 199})
      fee(%{name: "Service fee", kind: :percentage, rate_bp: 500})

      view = checkout(ctx, 24_000)

      assert has_element?(view, "#checkout-summary [data-role=total]", "$253.99")
    end

    test "draws no line for a row that comes to nothing", ctx do
      fee(%{name: "Protection fee", kind: :flat, amount: 0})

      view = checkout(ctx, 24_000)

      refute has_element?(view, "#checkout-summary", "Protection fee")
      assert has_element?(view, "#checkout-summary [data-role=total]", "$240.00")
    end

    test "totals the items alone where the marketplace charges a buyer nothing", ctx do
      view = checkout(ctx, 24_000)

      assert has_element?(view, "#checkout-summary [data-role=total]", "$240.00")
    end
  end
end
