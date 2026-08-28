defmodule MercatoWeb.Listings.BrowseLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers
  alias Mercato.Listings

  defp publish!(seller, listing) do
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp on_offer!(seller, opts \\ []) do
    publish!(seller, generate(listing(Keyword.put(opts, :actor, seller))))
  end

  defp sign_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  setup do
    %{seller: generate(user(first_name: "Marta", last_name: "Ribeiro"))}
  end

  describe "reaching the page" do
    test "opens at the site root for a visitor with no account", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse")
    end

    test "leads with what the grid is ordered by", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Newest listings"
    end
  end

  describe "the grid" do
    test "draws a card for a listing on offer", %{conn: conn, seller: seller} do
      listing = on_offer!(seller, title: "Eames-style lounge chair")

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse-listing-#{listing.id}")
      assert render(view) =~ "Eames-style lounge chair"
    end

    test "opens the listing from its card", %{conn: conn, seller: seller} do
      listing = on_offer!(seller)
      slug = Phoenix.Param.to_param(listing)

      {:ok, view, _html} = live(conn, ~p"/")

      assert view
             |> element(~s{#browse-listing-#{listing.id} a[href="/listings/#{slug}"]})
             |> has_element?()
    end

    test "names the seller on the card, since the grid spans every seller", %{
      conn: conn,
      seller: seller
    } do
      listing = on_offer!(seller)

      {:ok, view, _html} = live(conn, ~p"/")

      assert view
             |> element(~s{#browse-listing-#{listing.id} [data-role="meta"]})
             |> render() =~ "@#{seller.handle}"
    end

    test "says how recently the listing was published", %{conn: conn, seller: seller} do
      listing = on_offer!(seller)

      {:ok, view, _html} = live(conn, ~p"/")

      assert view
             |> element(~s{#browse-listing-#{listing.id} [data-role="meta"]})
             |> render() =~ "listed just now"
    end

    test "puts the most recently published first", %{conn: conn, seller: seller} do
      _older = on_offer!(seller, title: "Older listing")
      _newer = on_offer!(seller, title: "Newer listing")

      {:ok, _view, html} = live(conn, ~p"/")

      assert :binary.match(html, "Newer listing") < :binary.match(html, "Older listing")
    end

    test "gathers listings from every seller", %{conn: conn, seller: seller} do
      other = generate(user())
      on_offer!(seller, title: "From Marta")
      on_offer!(other, title: "From someone else")

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "From Marta"
      assert html =~ "From someone else"
    end
  end

  describe "what the grid leaves out" do
    test "a draft, which was never put in front of buyers", %{conn: conn, seller: seller} do
      generate(listing(actor: seller, title: "Unfinished draft"))

      {:ok, view, html} = live(conn, ~p"/")

      refute html =~ "Unfinished draft"
      assert has_element?(view, "#nothing-listed")
    end

    test "a paused listing, which the seller took out of view", %{conn: conn, seller: seller} do
      seller
      |> on_offer!(title: "Paused listing")
      |> Listings.pause_listing!(actor: seller)

      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "Paused listing"
    end

    test "a sold listing, which is no longer on offer", %{conn: conn, seller: seller} do
      seller
      |> on_offer!(title: "Already sold")
      |> Listings.mark_listing_sold!(actor: nil)

      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "Already sold"
    end

    test "the seller's own draft, even when they are the one browsing", %{
      conn: conn,
      seller: seller
    } do
      generate(listing(actor: seller, title: "My private draft"))

      {:ok, _view, html} = conn |> sign_in(seller) |> live(~p"/")

      refute html =~ "My private draft"
    end
  end

  describe "when nothing is on offer" do
    test "says so rather than drawing an empty grid", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#nothing-listed")
      refute has_element?(view, "#browse-grid")
    end

    test "offers a signed-in visitor the way to fix it", %{conn: conn, seller: seller} do
      {:ok, view, _html} = conn |> sign_in(seller) |> live(~p"/")

      assert view
             |> element(~s{#nothing-listed a[href="/listings/new"]})
             |> has_element?()
    end

    test "offers no such thing to someone with no account", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      refute has_element?(view, ~s{#nothing-listed a[href="/listings/new"]})
    end
  end
end
