defmodule MercatoWeb.Checkout.CheckoutLiveTest do
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
end
