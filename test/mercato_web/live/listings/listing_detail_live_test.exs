defmodule MercatoWeb.Listings.ListingDetailLiveTest do
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

  # Document order, which is the reading order at every width: the two sit in one
  # column on a phone and in one column beside the gallery on a desktop.
  defp position_of(html, id) do
    {at, _length} = :binary.match(html, ~s(id="#{id}"))

    at
  end

  defp classes_of(document, selector) do
    document |> LazyHTML.query(selector) |> LazyHTML.attribute("class") |> List.first()
  end

  defp gallery_of(seller, count) do
    listing = generate(listing(actor: seller))
    for _ <- 1..count, do: generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp strip_tags(html) do
    html |> String.replace(~r/<[^>]*>/, "") |> String.trim()
  end

  defp sold!(seller, listing) do
    Listings.mark_listing_sold!(publish!(seller, listing), actor: nil, authorize?: false)
  end

  setup do
    seller = generate(user(first_name: "Marta", last_name: "Ribeiro"))
    category = generate(category(name: "Furniture"))

    listing =
      publish!(
        seller,
        generate(
          listing(
            actor: seller,
            title: "Mid-century teak sideboard",
            description: "Danish teak, three drawers.",
            price: 34_750,
            quantity: 3,
            condition: "good",
            category_id: category.id
          )
        )
      )

    %{seller: seller, category: category, listing: listing}
  end

  describe "a listing on offer" do
    test "opens for a visitor with no account", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#listing-detail")
      assert has_element?(view, "#listing-title", "Mid-century teak sideboard")
    end

    test "names the listing before the photos on a narrow screen", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      html = render(view)

      assert has_element?(view, "#listing-title-compact", "Mid-century teak sideboard")
      assert position_of(html, "listing-title-compact") < position_of(html, "listing-gallery")
    end

    test "keeps the title at the head of the panel on a wide one", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#purchase-panel #listing-title", "Mid-century teak sideboard")
    end

    # Both are always in the markup and exactly one is ever displayed, so the
    # listing is named once at either width and a resize costs no re-render.
    test "shows only one of the two titles at any width", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      document = view |> render() |> LazyHTML.from_fragment()

      assert classes_of(document, "#listing-title-compact") =~ "lg:hidden"
      assert classes_of(document, "#purchase-panel #listing-title") =~ "hidden lg:block"
    end

    test "shows the price already formatted", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#listing-price", "$347.50")
    end

    test "shows what the seller wrote", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#listing-description", "Danish teak")
    end

    test "says how many are left", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#listing-availability", "3 available")
    end

    test "names the condition the way a person writes it", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#listing-condition", "Good")
    end

    test "leaves the condition chip out when the listing has none", %{conn: conn, seller: seller} do
      bare = publish!(seller, generate(listing(actor: seller, condition: nil)))

      {:ok, view, _html} = live(conn, ~p"/listings/#{bare}")

      refute has_element?(view, "#listing-condition")
    end

    test "names the category in the breadcrumb", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#listing-detail nav[aria-label='Breadcrumb']", "Furniture")
    end

    test "shows who is selling it", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#listing-seller", "Marta Ribeiro")
    end

    test "puts the seller card after the panel the price sits in", %{
      conn: conn,
      listing: listing
    } do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      html = render(view)

      assert position_of(html, "listing-seller") > position_of(html, "purchase-panel")
    end

    test "carries the buyer-protection promise under the buy action", %{
      conn: conn,
      listing: listing
    } do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#buyer-protection")
    end
  end

  describe "a long description" do
    @long String.duplicate("Danish teak sideboard in very good condition. ", 8)

    setup %{seller: seller} do
      %{wordy: publish!(seller, generate(listing(actor: seller, description: @long)))}
    end

    test "shows an opening of it and offers the rest", %{conn: conn, wordy: wordy} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{wordy}")

      assert has_element?(view, "#expand-description")
      refute render(view) =~ @long
    end

    test "keeps the opening within the preview length", %{conn: conn, wordy: wordy} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{wordy}")

      shown = view |> element("#description-text") |> render() |> strip_tags()

      assert String.length(shown) <= 141
    end

    test "reveals the whole thing when asked", %{conn: conn, wordy: wordy} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{wordy}")

      html = view |> element("#expand-description") |> render_click()

      assert html =~ String.trim(@long)
    end

    test "offers to fold it back up once open", %{conn: conn, wordy: wordy} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{wordy}")

      view |> element("#expand-description") |> render_click()
      assert has_element?(view, "#expand-description[aria-expanded=true]")

      view |> element("#expand-description") |> render_click()

      refute render(view) =~ String.trim(@long)
    end

    test "offers nothing to expand when the description already fits", %{
      conn: conn,
      listing: listing
    } do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      refute has_element?(view, "#expand-description")
    end
  end

  describe "the buy action" do
    test "offers a buy action to a visitor", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#buy-now")
    end

    test "says checkout is not built yet rather than pretending to charge", %{
      conn: conn,
      listing: listing
    } do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert view |> element("#buy-now") |> render_click() =~ "not available yet"
    end

    test "tells a visitor with no account that they need not make one", %{
      conn: conn,
      listing: listing
    } do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#buy-footnote", "without an account")
    end

    test "does not offer a signed-in buyer the chance to sign in", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(log_in(conn, generate(user())), ~p"/listings/#{listing}")

      assert has_element?(view, "#buy-footnote")
      refute has_element?(view, "#buy-footnote", "without an account")
      refute has_element?(view, "#buy-footnote", "Sign in")
    end

    test "says nothing is charged when the seller has run out, signed in or not", %{
      conn: conn,
      seller: seller
    } do
      empty = publish!(seller, generate(listing(actor: seller, quantity: 0)))

      {:ok, anon, _html} = live(conn, ~p"/listings/#{empty}")
      {:ok, buyer, _html} = live(log_in(conn, generate(user())), ~p"/listings/#{empty}")

      assert has_element?(anon, "#buy-footnote", "Nothing is charged")
      assert has_element?(buyer, "#buy-footnote", "Nothing is charged")
    end

    test "disables the buy action when the seller has run out", %{conn: conn, seller: seller} do
      empty = publish!(seller, generate(listing(actor: seller, quantity: 0)))

      {:ok, view, _html} = live(conn, ~p"/listings/#{empty}")

      assert has_element?(view, "#buy-now[disabled]")
      assert has_element?(view, "#listing-availability", "None left")
    end

    test "offers no buy action to the seller looking at their own listing", %{
      conn: conn,
      seller: seller,
      listing: listing
    } do
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing}")

      refute has_element?(view, "#buy-now")
    end
  end

  describe "the pinned buy bar" do
    test "stands aside for the panel's own buy action rather than covering it", %{
      conn: conn,
      listing: listing
    } do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#sticky-buy-bar[phx-hook=DeferToAction]")
      assert has_element?(view, ~s(#sticky-buy-bar[data-defer-to="buy-now"]))
    end

    test "is not pinned for a listing with no buy path at all", %{conn: conn, seller: seller} do
      sold = sold!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{sold}")

      refute has_element?(view, "#sticky-buy-bar")
    end
  end

  describe "the owner's own view" do
    test "frames the page as a preview of what buyers see", %{
      conn: conn,
      seller: seller,
      listing: listing
    } do
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing}")

      assert has_element?(view, "#owner-banner")
    end

    # The trail says where the page sits and belongs to the shell around it; the
    # banner is about this listing, so it comes after.
    test "sets the framing below the trail rather than above it", %{
      conn: conn,
      seller: seller,
      listing: listing
    } do
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing}")

      html = render(view)

      assert position_of(html, "owner-banner") > position_of(html, "listing-breadcrumb")
    end

    test "puts edit and pause where the buy action sits for buyers", %{
      conn: conn,
      seller: seller,
      listing: listing
    } do
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing}")

      assert has_element?(view, "#owner-primary", "Edit listing")
      assert has_element?(view, "#owner-secondary", "Pause listing")
    end

    test "labels an active listing the same way the seller's form does", %{
      conn: conn,
      seller: seller,
      listing: listing
    } do
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing}")

      assert has_element?(view, "#listing-status", "Active")
    end

    test "offers publishing on a draft, which was never public", %{conn: conn, seller: seller} do
      draft = generate(listing(actor: seller))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{draft}")

      assert has_element?(view, "#owner-primary", "Publish listing")
      assert has_element?(view, "#listing-status", "Draft")
    end

    test "offers resuming on a paused listing", %{conn: conn, seller: seller} do
      paused = paused!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{paused}")

      assert has_element?(view, "#owner-secondary", "Resume listing")
      assert has_element?(view, "#listing-status", "Paused")
    end

    test "publishes a draft from the page", %{conn: conn, seller: seller} do
      draft = generate(listing(actor: seller))
      generate(listing_image(listing: draft))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{draft}")

      assert view |> element("#owner-primary") |> render_click() =~ "on offer"
      assert %{status: :active} = Listings.get_listing!(draft.id, actor: seller)
    end

    test "pauses an active listing from the page", %{
      conn: conn,
      seller: seller,
      listing: listing
    } do
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing}")

      assert view |> element("#owner-secondary") |> render_click() =~ "paused"
      assert %{status: :unavailable} = Listings.get_listing!(listing.id, actor: seller)
    end

    test "resumes a paused listing from the page", %{conn: conn, seller: seller} do
      paused = paused!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{paused}")

      assert view |> element("#owner-secondary") |> render_click() =~ "back on offer"
      assert %{status: :active} = Listings.get_listing!(paused.id, actor: seller)
    end

    test "shows a sold listing as the record it is, with no buy path", %{
      conn: conn,
      seller: seller
    } do
      sold = sold!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{sold}")

      assert has_element?(view, "#listing-status", "Sold")
      assert has_element?(view, "#listing-closed")
      refute has_element?(view, "#buy-now")
      refute has_element?(view, "#owner-primary")
    end
  end

  describe "the buyer's view of state" do
    test "shows a buyer no lifecycle badge on a listing simply on offer", %{
      conn: conn,
      listing: listing
    } do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      refute has_element?(view, "#listing-status")
    end

    # Zero stock is recoverable and a sale is not, so it is its own mark rather
    # than a lifecycle state.
    test "marks a listing the seller has run out of", %{conn: conn, seller: seller} do
      empty = publish!(seller, generate(listing(actor: seller, quantity: 0)))

      {:ok, view, _html} = live(conn, ~p"/listings/#{empty}")

      assert has_element?(view, "#listing-stock", "Out of stock")
      refute has_element?(view, "#listing-status")
    end
  end

  describe "a listing nobody else may open" do
    test "reads as no longer available rather than as an error", %{conn: conn, seller: seller} do
      draft = generate(listing(actor: seller))

      {:ok, view, _html} = live(conn, ~p"/listings/#{draft}")

      assert has_element?(view, "#listing-gone")
      refute has_element?(view, "#listing-detail")
    end

    test "says the same of a paused listing, giving nothing away", %{conn: conn, seller: seller} do
      paused = paused!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(conn, ~p"/listings/#{paused}")

      assert has_element?(view, "#listing-gone")
    end

    test "says the same of a sold listing", %{conn: conn, seller: seller} do
      sold = sold!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(conn, ~p"/listings/#{sold}")

      assert has_element?(view, "#listing-gone")
    end

    test "says the same of a URL matching nothing at all", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/listings/a-listing-that-never-was-zzzzzzzz")

      assert has_element?(view, "#listing-gone")
    end
  end

  describe "the gallery" do
    test "shows the cover and a strip to move through the rest", %{conn: conn, seller: seller} do
      many = generate(listing(actor: seller))
      for _ <- 1..3, do: generate(listing_image(listing: many))
      many = Listings.publish_listing!(many, actor: seller)

      {:ok, view, _html} = live(conn, ~p"/listings/#{many}")

      assert has_element?(view, "#listing-gallery")
      assert has_element?(view, "#gallery-thumbs")
      assert has_element?(view, "#gallery-counter", "1 / 3")
    end

    test "moves the hero when a thumbnail is chosen", %{conn: conn, seller: seller} do
      many = generate(listing(actor: seller))
      for _ <- 1..3, do: generate(listing_image(listing: many))
      many = Listings.publish_listing!(many, actor: seller)

      {:ok, view, _html} = live(conn, ~p"/listings/#{many}")

      view |> element("#gallery-thumb-2") |> render_click()

      assert has_element?(view, "#gallery-counter", "3 / 3")
    end

    test "offers no strip, counter, or arrows for a single photo", %{conn: conn, listing: listing} do
      {:ok, view, _html} = live(conn, ~p"/listings/#{listing}")

      assert has_element?(view, "#listing-gallery")
      refute has_element?(view, "#gallery-thumbs")
      refute has_element?(view, "#gallery-counter")
      refute has_element?(view, "#gallery-previous")
      refute has_element?(view, "#gallery-next")
    end

    test "steps forward through the photos", %{conn: conn, seller: seller} do
      many = gallery_of(seller, 3)

      {:ok, view, _html} = live(conn, ~p"/listings/#{many}")

      view |> element("#gallery-next") |> render_click()

      assert has_element?(view, "#gallery-counter", "2 / 3")
    end

    test "steps back through the photos", %{conn: conn, seller: seller} do
      many = gallery_of(seller, 3)

      {:ok, view, _html} = live(conn, ~p"/listings/#{many}")

      view |> element("#gallery-thumb-2") |> render_click()
      view |> element("#gallery-previous") |> render_click()

      assert has_element?(view, "#gallery-counter", "2 / 3")
    end

    # Wrapping rather than stopping: a gallery this small has no end worth
    # marking, and a dead control at either edge reads as broken.
    test "wraps forward off the last photo", %{conn: conn, seller: seller} do
      many = gallery_of(seller, 3)

      {:ok, view, _html} = live(conn, ~p"/listings/#{many}")

      view |> element("#gallery-thumb-2") |> render_click()
      view |> element("#gallery-next") |> render_click()

      assert has_element?(view, "#gallery-counter", "1 / 3")
    end

    test "wraps back off the first photo", %{conn: conn, seller: seller} do
      many = gallery_of(seller, 3)

      {:ok, view, _html} = live(conn, ~p"/listings/#{many}")

      view |> element("#gallery-previous") |> render_click()

      assert has_element?(view, "#gallery-counter", "3 / 3")
    end
  end

  describe "the public URL" do
    test "names the listing before its public id", %{conn: conn, seller: seller} do
      live = publish!(seller, generate(listing(actor: seller, title: "Vintage Leather Jacket")))

      path = ~p"/listings/#{live}"

      assert path == "/listings/vintage-leather-jacket-#{live.public_id}"
      assert {:ok, view, _html} = live(conn, path)
      assert has_element?(view, "#listing-detail")
    end

    test "still resolves from a link shared before the seller retitled it", %{
      conn: conn,
      seller: seller
    } do
      live = publish!(seller, generate(listing(actor: seller, title: "Vintage Leather Jacket")))
      shared = ~p"/listings/#{live}"

      Listings.update_listing!(live, %{title: "Brown Leather Jacket"}, actor: seller)

      assert {:error, {:live_redirect, %{to: to}}} = live(conn, shared)
      assert to == "/listings/brown-leather-jacket-#{live.public_id}"
    end

    test "sends a stale title part on to the canonical URL", %{conn: conn, seller: seller} do
      live = publish!(seller, generate(listing(actor: seller, title: "Vintage Leather Jacket")))

      assert {:error, {:live_redirect, %{to: to}}} =
               live(conn, ~p"/listings/whatever-someone-typed-#{live.public_id}")

      assert to == "/listings/vintage-leather-jacket-#{live.public_id}"
    end

    test "leaves a URL that is already canonical alone", %{conn: conn, seller: seller} do
      live = publish!(seller, generate(listing(actor: seller, title: "Vintage Leather Jacket")))

      assert {:ok, _view, _html} = live(conn, ~p"/listings/#{live}")
    end

    test "does not redirect a listing the viewer may not see", %{conn: conn, seller: seller} do
      draft = generate(listing(actor: seller, title: "Not Yet Published"))

      assert {:ok, view, _html} = live(conn, ~p"/listings/#{draft}")
      assert has_element?(view, "#listing-gone")
    end
  end
end
