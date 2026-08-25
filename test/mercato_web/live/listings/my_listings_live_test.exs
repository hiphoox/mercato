defmodule MercatoWeb.Listings.MyListingsLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers
  alias Mercato.Listings

  defp log_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  defp publish!(seller, listing) do
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp paused!(seller, listing) do
    Listings.pause_listing!(publish!(seller, listing), actor: seller)
  end

  defp sold!(seller, listing) do
    Listings.mark_listing_sold!(publish!(seller, listing), actor: nil, authorize?: false)
  end

  describe "access" do
    test "redirects a signed-out visitor to sign-in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/my-listings")
    end

    test "lets a signed-in seller in", %{conn: conn} do
      seller = generate(user())

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/my-listings")

      assert has_element?(view, "#my-listings")
    end
  end

  describe "the seller's listings" do
    setup %{conn: conn} do
      seller = generate(user())

      draft = generate(listing(actor: seller, title: "A draft chair"))
      live_one = publish!(seller, generate(listing(actor: seller, title: "A live lamp")))
      paused = paused!(seller, generate(listing(actor: seller, title: "A paused bike")))
      sold = sold!(seller, generate(listing(actor: seller, title: "A sold camera")))

      %{
        conn: log_in(conn, seller),
        seller: seller,
        draft: draft,
        live: live_one,
        paused: paused,
        sold: sold
      }
    end

    test "shows a card for every listing the seller owns", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings")

      for listing <- [ctx.draft, ctx.live, ctx.paused, ctx.sold] do
        assert has_element?(view, "#listing-#{listing.id}")
      end
    end

    test "groups them into a section per state", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings")

      for status <- ~w(draft active unavailable sold) do
        assert has_element?(view, "#section-#{status}")
      end
    end

    test "leaves out another seller's listing, even one on offer", ctx do
      other = generate(user())
      theirs = publish!(other, generate(listing(actor: other)))

      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings")

      refute has_element?(view, "#listing-#{theirs.id}")
    end

    test "offers no way to remove a sold listing, which is a sales record", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings")

      assert has_element?(view, "#remove-#{ctx.live.id}")
      refute has_element?(view, "#remove-#{ctx.sold.id}")
    end

    test "asks the browser to confirm before removing", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings")

      assert view |> element("#remove-#{ctx.live.id}") |> render() =~ "data-confirm"
    end
  end

  describe "filtering by state" do
    setup %{conn: conn} do
      seller = generate(user())

      draft = generate(listing(actor: seller))
      live_one = publish!(seller, generate(listing(actor: seller)))

      %{conn: log_in(conn, seller), seller: seller, draft: draft, live: live_one}
    end

    test "narrows to one state from the URL", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings?status=draft")

      assert has_element?(view, "#listing-#{ctx.draft.id}")
      refute has_element?(view, "#listing-#{ctx.live.id}")
    end

    test "a chip puts its state in the URL, so a filtered view is shareable", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings")

      view |> element("#status-chip-draft") |> render_click()

      assert_patched(view, ~p"/my-listings?status=draft")
    end

    test "the All chip clears the filter", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings?status=draft")

      view |> element("#status-chip-all") |> render_click()

      assert_patched(view, ~p"/my-listings")
    end

    test "an unknown state in the URL falls back to showing everything", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings?status=nonsense")

      assert has_element?(view, "#listing-#{ctx.draft.id}")
      assert has_element?(view, "#listing-#{ctx.live.id}")
    end

    test "says so when the chosen state holds nothing", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/my-listings?status=sold")

      assert has_element?(view, "#no-matching-listings")
      refute has_element?(view, "#no-listings")
    end
  end

  describe "a seller who has listed nothing" do
    setup %{conn: conn} do
      %{conn: log_in(conn, generate(user()))}
    end

    test "gets the first-listing empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-listings")

      assert has_element?(view, "#no-listings")
    end

    test "is not offered filter chips there is nothing to filter", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-listings")

      refute has_element?(view, "#status-chip-all")
    end

    test "can still start a listing from there", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-listings")

      assert has_element?(view, "#new-listing")
    end
  end
end
