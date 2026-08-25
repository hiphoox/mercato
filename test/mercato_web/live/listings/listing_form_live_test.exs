defmodule MercatoWeb.Listings.ListingFormLiveTest do
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

  defp value(view, selector) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute("value")
    |> List.first()
  end

  describe "access" do
    test "redirects a signed-out visitor away from the new form", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/listings/new")
    end

    test "redirects a signed-out visitor away from the edit form", %{conn: conn} do
      listing = generate(listing())

      assert {:error, {:redirect, %{to: "/sign-in"}}} =
               live(conn, ~p"/listings/#{listing.id}/edit")
    end

    test "lets a signed-in seller compose a new listing", %{conn: conn} do
      seller = generate(user())

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/new")

      assert has_element?(view, "#listing-form")
    end

    test "sends a seller opening someone else's listing back to their own", %{conn: conn} do
      seller = generate(user())
      other = generate(user())
      theirs = publish!(other, generate(listing(actor: other)))

      assert {:error, {:live_redirect, %{to: "/my-listings"}}} =
               live(log_in(conn, seller), ~p"/listings/#{theirs.id}/edit")
    end

    test "sends a seller away from a listing that has sold", %{conn: conn} do
      seller = generate(user())

      sold =
        Mercato.Listings.mark_listing_sold!(publish!(seller, generate(listing(actor: seller))),
          actor: nil,
          authorize?: false
        )

      assert {:error, {:live_redirect, %{to: "/my-listings"}}} =
               live(log_in(conn, seller), ~p"/listings/#{sold.id}/edit")
    end

    test "sends a seller opening a listing that is not there back to their own", %{conn: conn} do
      seller = generate(user())

      assert {:error, {:live_redirect, %{to: "/my-listings"}}} =
               live(log_in(conn, seller), ~p"/listings/#{Ash.UUID.generate()}/edit")
    end
  end

  describe "composing a new listing" do
    setup %{conn: conn} do
      seller = generate(user())
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/new")

      %{seller: seller, view: view}
    end

    test "names the page for what it is doing", %{view: view} do
      assert view |> element("h1") |> render() =~ "New listing"
    end

    test "trails a breadcrumb back to the seller's own listings", %{view: view} do
      assert has_element?(view, "nav[aria-label=Breadcrumb] a[href='/my-listings']")
    end

    test "offers the fields a listing is made of", %{view: view} do
      assert has_element?(view, "#listing_title")
      assert has_element?(view, "#listing_description")
      assert has_element?(view, "#listing_price")
      assert has_element?(view, "#listing_quantity")
      assert has_element?(view, "#listing_category_id")
      assert has_element?(view, "#listing_condition")
    end

    test "starts every field blank but the quantity most sellers want", %{view: view} do
      assert value(view, "#listing_title") in [nil, ""]
      assert value(view, "#listing_price") in [nil, ""]
      assert value(view, "#listing_quantity") == "1"
    end

    test "offers the seeded catalog to file the listing under" do
      category = generate(category(name: "Furniture"))

      {:ok, view, _html} =
        live(log_in(build_conn(), generate(user())), ~p"/listings/new")

      assert has_element?(view, "#listing_category_id option[value='#{category.id}']")
      assert view |> element("#listing_category_id") |> render() =~ "Furniture"
    end

    test "offers the conditions this marketplace configures, and no others", %{view: view} do
      for condition <- Listings.conditions() do
        assert has_element?(view, "#listing_condition input[value='#{condition}']")
      end

      refute has_element?(view, "#listing_condition input[value='for_parts']")
    end

    test "lets the seller leave the condition blank, as the domain allows", %{view: view} do
      assert has_element?(view, "#listing_condition input[value='']")
    end

    test "publishes rather than saves changes", %{view: view} do
      assert view |> element("#publish-listing") |> render() =~ "Publish"
      assert has_element?(view, "#save-draft")
    end

    test "offers no pause control, since there is nothing on offer yet", %{view: view} do
      refute has_element?(view, "#pause-listing")
    end

    test "shows the currency the marketplace prices in beside the amount", %{view: view} do
      assert view |> element("#listing-price-field") |> render() =~
               Mercato.Money.symbol(Listings.currency())
    end
  end

  describe "photos on a new listing" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(log_in(conn, generate(user())), ~p"/listings/new")

      %{view: view}
    end

    test "says the gallery is empty rather than showing nothing", %{view: view} do
      assert view |> element("#listing-photos") |> render() =~ "None yet"
    end

    test "offers a way to add photos, naming the limit", %{view: view} do
      assert view |> element("#add-photos") |> render() =~ to_string(Listings.max_images())
    end
  end

  describe "editing a listing already on offer" do
    setup %{conn: conn} do
      seller = generate(user())

      listing =
        publish!(
          seller,
          generate(
            listing(
              actor: seller,
              title: "Eames-style lounge chair",
              description: "Walnut veneer, tan leather.",
              price: 42_000,
              quantity: 2,
              condition: "good"
            )
          )
        )

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    test "names the page for what it is doing", %{view: view} do
      assert view |> element("h1") |> render() =~ "Edit listing"
    end

    test "says what state the listing is in", %{view: view} do
      assert view |> element("#listing-status") |> render() =~ "Live"
    end

    test "fills the fields with what the seller last saved", %{view: view} do
      assert value(view, "#listing_title") == "Eames-style lounge chair"
      assert value(view, "#listing_quantity") == "2"
      assert view |> element("#listing_description") |> render() =~ "Walnut veneer"
    end

    test "shows the price as a person reads it, not in minor units", %{view: view} do
      assert value(view, "#listing_price") == "420.00"
    end

    test "checks the condition already recorded", %{view: view} do
      assert has_element?(view, "#listing_condition input[value=good][checked]")
    end

    test "saves changes rather than publishing again", %{view: view} do
      assert view |> element("#publish-listing") |> render() =~ "Save changes"
    end

    test "offers pausing as the alternative to saving", %{view: view} do
      assert has_element?(view, "#pause-listing")
    end

    test "shows the gallery the listing already has, marking the cover", %{
      view: view,
      listing: listing
    } do
      [image] = Listings.list_listing_images!(listing.id, authorize?: false)

      assert has_element?(view, "#photo-#{image.id}")
      assert view |> element("#photo-#{image.id}") |> render() =~ "Cover"
    end

    test "counts the gallery against the marketplace's limit", %{view: view} do
      assert view |> element("#listing-photos") |> render() =~ "1 of #{Listings.max_images()}"
    end
  end

  describe "editing a paused listing" do
    setup %{conn: conn} do
      seller = generate(user())

      paused =
        Listings.pause_listing!(publish!(seller, generate(listing(actor: seller))), actor: seller)

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{paused.id}/edit")

      %{view: view}
    end

    test "saves changes rather than publishing, since it was published before", %{view: view} do
      assert view |> element("#publish-listing") |> render() =~ "Save changes"
    end

    test "says it is paused", %{view: view} do
      assert view |> element("#listing-status") |> render() =~ "Paused"
    end

    test "offers no pause control for a listing already paused", %{view: view} do
      refute has_element?(view, "#pause-listing")
    end
  end

  describe "editing a draft" do
    setup %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    test "publishes rather than saving changes, since it is not on offer yet", %{view: view} do
      assert view |> element("#publish-listing") |> render() =~ "Publish"
    end

    test "offers no pause control for a listing nobody can see", %{view: view} do
      refute has_element?(view, "#pause-listing")
    end

    test "says it is a draft", %{view: view} do
      assert view |> element("#listing-status") |> render() =~ "Draft"
    end
  end
end
