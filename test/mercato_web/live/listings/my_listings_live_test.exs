defmodule MercatoWeb.Listings.MyListingsLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers
  alias Mercato.Listings
  alias Mercato.Listings.Listing.Slug

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
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/users/me/listings")
    end

    test "lets a signed-in seller in", %{conn: conn} do
      seller = generate(user())

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/users/me/listings")

      assert has_element?(view, "#my-listings")
    end
  end

  describe "opening a listing" do
    setup %{conn: conn} do
      seller = generate(user())
      draft = generate(listing(actor: seller, title: "A draft chair"))

      %{conn: log_in(conn, seller), draft: draft}
    end

    test "the photo opens the listing's own page", %{conn: conn, draft: draft} do
      {:ok, view, _html} = live(conn, ~p"/users/me/listings")

      assert has_element?(
               view,
               ~s(#listing-#{draft.id} [data-role=photo] a[href="/listings/#{Slug.slug(draft)}"])
             )
    end

    test "the title opens it too", %{conn: conn, draft: draft} do
      {:ok, view, _html} = live(conn, ~p"/users/me/listings")

      assert has_element?(
               view,
               ~s(#listing-#{draft.id} [data-role=title] a[href="/listings/#{Slug.slug(draft)}"])
             )
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
      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings")

      for listing <- [ctx.draft, ctx.live, ctx.paused, ctx.sold] do
        assert has_element?(view, "#listing-#{listing.id}")
      end
    end

    test "groups them into a section per state", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings")

      for status <- ~w(draft active unavailable sold) do
        assert has_element?(view, "#section-#{status}")
      end
    end

    test "leaves out another seller's listing, even one on offer", ctx do
      other = generate(user())
      theirs = publish!(other, generate(listing(actor: other)))

      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings")

      refute has_element?(view, "#listing-#{theirs.id}")
    end

    test "offers no way to remove a sold listing, which is a sales record", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings")

      assert has_element?(view, "#remove-#{ctx.live.id}")
      refute has_element?(view, "#remove-#{ctx.sold.id}")
    end

    test "asks the browser to confirm before removing", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings")

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
      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings?status=draft")

      assert has_element?(view, "#listing-#{ctx.draft.id}")
      refute has_element?(view, "#listing-#{ctx.live.id}")
    end

    test "a chip puts its state in the URL, so a filtered view is shareable", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings")

      view |> element("#status-chip-draft") |> render_click()

      assert_patched(view, ~p"/users/me/listings?status=draft")
    end

    test "the All chip clears the filter", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings?status=draft")

      view |> element("#status-chip-all") |> render_click()

      assert_patched(view, ~p"/users/me/listings")
    end

    test "an unknown state in the URL falls back to showing everything", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings?status=nonsense")

      assert has_element?(view, "#listing-#{ctx.draft.id}")
      assert has_element?(view, "#listing-#{ctx.live.id}")
    end

    test "says so when the chosen state holds nothing", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users/me/listings?status=sold")

      assert has_element?(view, "#no-matching-listings")
      refute has_element?(view, "#no-listings")
    end
  end

  describe "a seller who has listed nothing" do
    setup %{conn: conn} do
      %{conn: log_in(conn, generate(user()))}
    end

    test "gets the first-listing empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/me/listings")

      assert has_element?(view, "#no-listings")
    end

    test "is not offered filter chips there is nothing to filter", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/me/listings")

      refute has_element?(view, "#status-chip-all")
    end

    test "can still start a listing from there", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/me/listings")

      assert has_element?(view, "#new-listing")
    end
  end

  describe "removing a listing" do
    setup %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller, title: "Eames-style lounge chair"))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/users/me/listings")

      %{seller: seller, listing: listing, view: view}
    end

    test "takes it off Mercato", %{seller: seller, listing: listing, view: view} do
      view |> element("#remove-#{listing.id}") |> render_click()

      assert Listings.list_my_listings!(actor: seller) == []
    end

    test "takes it off the page it was removed from", %{listing: listing, view: view} do
      view |> element("#remove-#{listing.id}") |> render_click()

      refute has_element?(view, "#remove-#{listing.id}")
    end

    test "says so", %{listing: listing, view: view} do
      view |> element("#remove-#{listing.id}") |> render_click()

      assert view |> element("#flash-info") |> render() =~ "removed"
    end

    test "takes the gallery and its files with it", %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller))
      image = generate(listing_image(listing: listing))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/users/me/listings")
      view |> element("#remove-#{listing.id}") |> render_click()

      storage = Application.fetch_env!(:mercato, :storage_adapter)
      assert {:error, _gone} = storage.get(image.storage_key)
    end

    test "offers no removal of a sold listing, which is the record of a sale", %{conn: conn} do
      seller = generate(user())
      sold = sold!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/users/me/listings")

      refute has_element?(view, "#remove-#{sold.id}")
    end

    test "asks before doing it", %{listing: listing, view: view} do
      assert view |> element("#remove-#{listing.id}") |> render() =~ "data-confirm"
    end
  end

  describe "pausing and relisting from the shelf" do
    test "pausing takes a live listing off offer", %{conn: conn} do
      seller = generate(user())
      listing = publish!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/users/me/listings")
      view |> element("#pause-#{listing.id}") |> render_click()

      assert {:ok, %{status: :unavailable}} = Listings.get_my_listing(listing.id, actor: seller)
      assert view |> element("#flash-info") |> render() =~ "paused"
    end

    test "a paused listing moves into the paused section", %{conn: conn} do
      seller = generate(user())
      listing = publish!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/users/me/listings")
      view |> element("#pause-#{listing.id}") |> render_click()

      assert has_element?(view, "#resume-#{listing.id}")
      refute has_element?(view, "#pause-#{listing.id}")
    end

    test "relisting puts a paused listing back on offer", %{conn: conn} do
      seller = generate(user())
      listing = paused!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/users/me/listings")
      view |> element("#resume-#{listing.id}") |> render_click()

      assert {:ok, %{status: :active}} = Listings.get_my_listing(listing.id, actor: seller)
      assert view |> element("#flash-info") |> render() =~ "on offer"
    end

    test "refuses to relist a listing stripped of the photos it needs", %{conn: conn} do
      seller = generate(user())
      listing = paused!(seller, generate(listing(actor: seller)))

      for image <- Listings.list_listing_images!(listing.id, authorize?: false) do
        :ok = Listings.delete_listing_image(image, actor: seller)
      end

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/users/me/listings")
      view |> element("#resume-#{listing.id}") |> render_click()

      assert {:ok, %{status: :unavailable}} = Listings.get_my_listing(listing.id, actor: seller)
      assert view |> element("#flash-error") |> render() =~ "back on offer"
    end
  end
end
