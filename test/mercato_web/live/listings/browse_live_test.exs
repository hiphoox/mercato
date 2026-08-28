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

    test "says what the grid holds, leaving the order to the bar", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Everything on offer"
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

  describe "searching" do
    test "narrows the grid to what matches the term", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Eames-style lounge chair")
      on_offer!(seller, title: "Two-person tent")

      {:ok, _view, html} = live(conn, ~p"/?q=lounge")

      assert html =~ "Eames-style lounge chair"
      refute html =~ "Two-person tent"
    end

    test "matches on the description too, not just the title", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Nondescript item", description: "Walnut shell, barely used")

      {:ok, _view, html} = live(conn, ~p"/?q=walnut")

      assert html =~ "Nondescript item"
    end

    test "ignores case", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Steel-Frame ROAD Bike")

      {:ok, _view, html} = live(conn, ~p"/?q=road+bike")

      assert html =~ "Steel-Frame ROAD Bike"
    end

    test "says what was asked and how much came back", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Lounge chair")

      {:ok, _view, html} = live(conn, ~p"/?q=lounge")

      assert html =~ "1 result for"
      assert html =~ "lounge"
    end

    test "counts every match in the heading", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Lounge chair, walnut")
      on_offer!(seller, title: "Lounge chair, oak")

      {:ok, _view, html} = live(conn, ~p"/?q=lounge")

      assert html =~ "2 results for"
    end

    test "leaves the term in the header's box after searching", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Lounge chair")

      {:ok, view, _html} = live(conn, ~p"/?q=lounge")

      assert view |> element("#app-search") |> render() =~ ~s(value="lounge")
    end

    test "treats a blank term as no search at all", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Two-person tent")

      {:ok, _view, html} = live(conn, ~p"/?q=")

      assert html =~ "Everything on offer"
      assert html =~ "Two-person tent"
    end

    test "still hides a draft that matches the term", %{conn: conn, seller: seller} do
      generate(listing(actor: seller, title: "Draft lounge chair"))

      {:ok, _view, html} = live(conn, ~p"/?q=lounge")

      refute html =~ "Draft lounge chair"
    end
  end

  describe "when a search matches nothing" do
    setup %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Two-person tent")

      {:ok, view, html} = live(conn, ~p"/?q=harpsichord")

      %{view: view, html: html}
    end

    test "says so rather than drawing an empty grid", %{view: view} do
      assert has_element?(view, "#no-results")
      refute has_element?(view, "#browse-grid")
    end

    test "names the term that found nothing", %{html: html} do
      assert html =~ "No results for"
      assert html =~ "harpsichord"
    end

    test "keeps the empty state apart from the one for an empty marketplace", %{view: view} do
      refute has_element?(view, "#nothing-listed")
    end

    test "clears the search back to the whole shelf", %{view: view} do
      view |> element("#clear-search") |> render_click()

      assert_patched(view, "/")
      assert render(view) =~ "Two-person tent"
      assert render(view) =~ "Everything on offer"
    end
  end

  describe "scoping the grid to a category" do
    setup %{seller: seller} do
      furniture = generate(category(name: "Furniture", slug: "furniture"))
      outdoor = generate(category(name: "Outdoor", slug: "outdoor"))

      on_offer!(seller, title: "Eames-style lounge chair", category_id: furniture.id)
      on_offer!(seller, title: "Two-person tent", category_id: outdoor.id)

      %{furniture: furniture, outdoor: outdoor}
    end

    test "narrows the grid to the category named in the URL", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/?category=furniture")

      assert html =~ "Eames-style lounge chair"
      refute html =~ "Two-person tent"
    end

    test "narrows by the term and the scope together", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Folding chair", category_id: generate(category()).id)

      {:ok, _view, html} = live(conn, ~p"/?q=chair&category=furniture")

      assert html =~ "Eames-style lounge chair"
      refute html =~ "Folding chair"
    end

    test "reads the scope back into the header, so it survives a search", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?category=furniture")

      assert view
             |> element(~s{#app-search-scope option[value="furniture"][selected]})
             |> has_element?()
    end

    test "falls back to the whole shelf for a category nobody has", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/?category=harpsichords")

      assert html =~ "Eames-style lounge chair"
      assert html =~ "Two-person tent"
    end

    test "says the category is empty rather than that nothing is listed at all", %{conn: conn} do
      generate(category(name: "Vehicles", slug: "vehicles"))

      {:ok, view, html} = live(conn, ~p"/?category=vehicles")

      assert has_element?(view, "#no-results")
      refute has_element?(view, "#nothing-listed")
      assert html =~ "Vehicles"
    end

    test "clears the scope and the term together", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?q=harpsichord&category=furniture")

      view |> element("#clear-search") |> render_click()

      assert_patched(view, "/")
      assert render(view) =~ "Two-person tent"
    end
  end

  describe "the filter bar" do
    setup %{seller: seller} do
      furniture = generate(category(name: "Furniture", slug: "furniture"))
      generate(category(name: "Outdoor", slug: "outdoor"))

      on_offer!(seller, title: "Eames-style lounge chair", category_id: furniture.id)

      :ok
    end

    test "sits between the heading and the grid", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse-filters")
    end

    test "names the facet while nothing narrows it", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert view |> element("#browse-category-trigger") |> render() =~ "Category"
    end

    test "names the scope in force instead, so the row reads as one sentence", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?category=furniture")

      assert view |> element("#browse-category-trigger") |> render() =~ "Furniture"
    end

    test "offers every category the header offers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse-category-panel", "Furniture")
      assert has_element?(view, "#browse-category-panel", "Outdoor")
    end

    test "scopes the grid from the bar, not just from the header", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("#browse-category-furniture") |> render_click()

      assert_patched(view, "/?category=furniture")
    end

    test "keeps the term when the scope is picked, since they narrow together", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?q=chair")

      view |> element("#browse-category-furniture") |> render_click()

      assert_patched(view, "/?category=furniture&q=chair")
    end

    test "marks the scope in force as chosen", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?category=furniture")

      assert view
             |> element(~s{#browse-category-furniture[aria-checked="true"]})
             |> has_element?()
    end

    test "offers a way back to the whole shelf from inside the menu", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?category=furniture")

      view |> element("#browse-category-any") |> render_click()

      assert_patched(view, "/")
    end

    test "orders the grid by recency, and says so on the pill", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert view |> element("#browse-sort-trigger") |> render() =~ "Newest"
    end

    test "opens the rest of the filters in a sheet", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse-all-filters")
      assert has_element?(view, "#browse-filters-sheet")
    end
  end

  describe "the filter bar when nothing is listed" do
    test "is left out, since there is nothing to narrow", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#nothing-listed")
      refute has_element?(view, "#browse-filters")
    end
  end

  describe "the filters in force" do
    setup %{seller: seller} do
      furniture = generate(category(name: "Furniture", slug: "furniture"))

      on_offer!(seller, title: "Eames-style lounge chair", category_id: furniture.id)

      :ok
    end

    test "shows no chips while nothing is applied", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      refute has_element?(view, "#browse-filters-chips")
    end

    test "shows the term as a chip of its own", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?q=chair")

      assert has_element?(view, "#browse-filters-chips", "chair")
    end

    test "shows the scope as a chip of its own", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?category=furniture")

      assert has_element?(view, "#browse-filters-chips", "Furniture")
    end

    test "drops the scope and keeps the term", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?q=chair&category=furniture")

      view |> element("#browse-chip-category") |> render_click()

      assert_patched(view, "/?q=chair")
    end

    test "drops the term and keeps the scope", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?q=chair&category=furniture")

      view |> element("#browse-chip-query") |> render_click()

      assert_patched(view, "/?category=furniture")
    end

    test "drops everything at once", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?q=chair&category=furniture")

      view |> element("#browse-clear-all") |> render_click()

      assert_patched(view, "/")
    end
  end

  describe "ordering the grid" do
    setup %{seller: seller} do
      furniture = generate(category(name: "Furniture", slug: "furniture"))

      # Cheapest published first, so recency and price disagree — an order the
      # grid has not applied cannot pass by coincidence.
      %{
        cheap: on_offer!(seller, title: "Cheap chair", price: 1_000, category_id: furniture.id),
        dear: on_offer!(seller, title: "Dear chair", price: 90_000, category_id: furniture.id)
      }
    end

    test "reads the order out of the URL", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/?sort=price_asc")

      assert view |> element("#browse-grid") |> render() =~ "Cheap chair"

      assert [ctx.cheap.id, ctx.dear.id] ==
               Regex.scan(~r/browse-listing-([0-9a-f-]+)/, render(view))
               |> Enum.map(&List.last/1)
               |> Enum.uniq()
    end

    test "labels the pill with the order in force", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?sort=price_desc")

      assert view |> element("#browse-sort-trigger") |> render() =~ "Price: high to low"
    end

    test "marks the order in force as chosen", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?sort=price_asc")

      assert has_element?(view, ~s{#browse-sort-price_asc[aria-checked="true"]})
      refute has_element?(view, ~s{#browse-sort-newest[aria-checked="true"]})
    end

    test "picks the order from the bar", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("#browse-sort-price_asc") |> render_click()

      assert_patched(view, "/?sort=price_asc")
    end

    test "keeps the term and the scope when the order changes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?q=chair&category=furniture")

      view |> element("#browse-sort-price_desc") |> render_click()

      assert_patched(view, "/?category=furniture&q=chair&sort=price_desc")
    end

    test "keeps the order when the scope changes, since an order is not a filter", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?sort=price_asc")

      view |> element("#browse-category-furniture") |> render_click()

      assert_patched(view, "/?category=furniture&sort=price_asc")
    end

    test "keeps the order when the filters are cleared", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?q=chair&sort=price_asc")

      view |> element("#browse-clear-all") |> render_click()

      assert_patched(view, "/?sort=price_asc")
    end

    test "leaves the order out of the URL while it is the default", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?q=chair")

      view |> element("#browse-sort-newest") |> render_click()

      assert_patched(view, "/?q=chair")
    end

    test "falls back to newest for an order nobody has", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?sort=cheapest_nearby")

      assert view |> element("#browse-sort-trigger") |> render() =~ "Newest"
      assert has_element?(view, ~s{#browse-sort-newest[aria-checked="true"]})
    end

    test "offers the same orders in the sheet as on the bar", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse-sheet-sort-newest")
      assert has_element?(view, "#browse-sheet-sort-price_asc")
      assert has_element?(view, "#browse-sheet-sort-price_desc")
    end
  end
end
