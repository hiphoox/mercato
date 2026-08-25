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

  describe "validating as the seller types" do
    setup %{conn: conn} do
      seller = generate(user())
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/new")

      %{seller: seller, view: view}
    end

    defp change(view, params) do
      view |> form("#listing-form", listing: params) |> render_change()
    end

    test "says nothing is wrong about a form nobody has filled in yet", %{view: view} do
      refute has_element?(view, "#listing_title.border-error")
      refute has_element?(view, "#listing_price.border-error")
    end

    test "marks a title too short to identify the item", %{view: view} do
      change(view, %{title: "ab"})

      assert has_element?(view, "#listing_title.border-error")
    end

    test "clears the mark once the title is long enough", %{view: view} do
      change(view, %{title: "ab"})
      change(view, %{title: "Eames-style lounge chair"})

      refute has_element?(view, "#listing_title.border-error")
    end

    test "says what is wrong, not only that something is", %{view: view} do
      html = change(view, %{title: "ab"})

      assert html =~ "greater than or equal to 3"
    end

    test "keeps the price the seller typed rather than reverting it", %{view: view} do
      change(view, %{price: "24.99"})

      assert value(view, "#listing_price") == "24.99"
    end

    test "reads a typed price as the minor units a listing stores", %{view: view} do
      # A listing may not be free, so a price the marketplace refuses is proof
      # the typed major units reached the changeset as minor ones.
      change(view, %{price: "0.00"})
      assert has_element?(view, "#listing_price.border-error")

      change(view, %{price: "0.01"})
      refute has_element?(view, "#listing_price.border-error")
    end

    test "refuses a price carrying more precision than the currency has", %{view: view} do
      change(view, %{price: "24.999"})

      assert has_element?(view, "#listing_price.border-error")
    end

    test "refuses a price that is not an amount at all", %{view: view} do
      change(view, %{price: "free"})

      assert has_element?(view, "#listing_price.border-error")
    end

    test "shows a seller what an amount looks like rather than calling it invalid", %{view: view} do
      html = change(view, %{price: "free"})

      assert html =~ "24.99"
      refute view |> element("#listing-price-field") |> render() =~ "is invalid"
    end

    test "still names the marketplace's own floor for a price it could read", %{view: view} do
      html = change(view, %{price: "0.00"})

      assert has_element?(view, "#listing_price.border-error")
      refute html =~ "24.99"
    end

    test "asks again for a price the seller has cleared", %{view: view} do
      change(view, %{price: "24.99"})
      change(view, %{price: ""})

      assert has_element?(view, "#listing_price.border-error")
    end

    test "leaves the description alone, which a listing need not carry", %{view: view} do
      change(view, %{description: ""})

      refute has_element?(view, "#listing_description.border-error")
    end
  end

  describe "validating a listing already saved" do
    setup %{conn: conn} do
      seller = generate(user())

      listing =
        generate(listing(actor: seller, title: "Eames-style lounge chair", price: 42_000))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    test "shows the stored price until the seller types over it", %{view: view} do
      assert value(view, "#listing_price") == "420.00"
    end

    test "keeps a newly typed price over the one stored", %{view: view} do
      change(view, %{price: "99.95"})

      assert value(view, "#listing_price") == "99.95"
    end

    test "marks a title the seller has emptied", %{view: view} do
      change(view, %{title: ""})

      assert has_element?(view, "#listing_title.border-error")
    end
  end

  describe "saving a new listing" do
    setup %{conn: conn} do
      seller = generate(user())
      category = generate(category())
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/new")

      %{seller: seller, category: category, view: view}
    end

    defp submit(view, params) do
      view |> form("#listing-form", listing: params) |> render_submit()
    end

    defp fields(category, overrides \\ %{}) do
      Map.merge(
        %{
          title: "Eames-style lounge chair",
          description: "Walnut veneer.",
          price: "420.00",
          quantity: "1",
          category_id: category.id
        },
        overrides
      )
    end

    test "keeps what the seller wrote even when it cannot go on offer yet", %{
      seller: seller,
      category: category,
      view: view
    } do
      submit(view, fields(category))

      assert [listing] = Listings.list_my_listings!(actor: seller)
      assert listing.title == "Eames-style lounge chair"
      assert listing.status == :draft
    end

    test "reads the typed price back as the minor units a listing stores", %{
      seller: seller,
      category: category,
      view: view
    } do
      submit(view, fields(category, %{price: "99.95"}))

      assert [%{price: 9995}] = Listings.list_my_listings!(actor: seller)
    end

    test "says on the gallery itself why it could not go on offer", %{
      category: category,
      view: view
    } do
      submit(view, fields(category))

      assert view |> element("#listing-photos") |> render() =~
               "at least #{Listings.min_images()}"
    end

    test "carries on editing the listing it just made", %{
      seller: seller,
      category: category,
      view: view
    } do
      submit(view, fields(category))

      [listing] = Listings.list_my_listings!(actor: seller)
      assert_patched(view, "/listings/#{listing.id}/edit")
    end

    test "saving twice edits the one listing rather than making another", %{
      seller: seller,
      category: category,
      view: view
    } do
      submit(view, fields(category))
      submit(view, fields(category, %{title: "Eames-style lounge chair, walnut"}))

      assert [listing] = Listings.list_my_listings!(actor: seller)
      assert listing.title == "Eames-style lounge chair, walnut"
    end

    test "writes nothing at all when a field is refused", %{
      seller: seller,
      category: category,
      view: view
    } do
      submit(view, fields(category, %{title: "ab"}))

      assert Listings.list_my_listings!(actor: seller) == []
      assert has_element?(view, "#listing_title.border-error")
    end
  end

  describe "publishing a draft that has its photos" do
    setup %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller, title: "Eames-style lounge chair"))
      generate(listing_image(listing: listing))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    test "puts the listing on offer", %{seller: seller, listing: listing, view: view} do
      view
      |> form("#listing-form", listing: %{title: "Eames-style lounge chair, walnut"})
      |> render_submit()

      assert {:ok, saved} = Listings.get_my_listing(listing.id, actor: seller)
      assert saved.status == :active
      assert saved.title == "Eames-style lounge chair, walnut"
      assert saved.published_at
    end

    test "the page now offers to save changes rather than to publish again", %{view: view} do
      view |> form("#listing-form", listing: %{}) |> render_submit()

      assert view |> element("#publish-listing") |> render() =~ "Save changes"
      assert view |> element("#listing-status") |> render() =~ "Live"
    end
  end

  describe "saving a listing already on offer" do
    setup %{conn: conn} do
      seller = generate(user())
      listing = publish!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    test "saves the change and leaves it on offer", %{
      seller: seller,
      listing: listing,
      view: view
    } do
      view |> form("#listing-form", listing: %{title: "A better title"}) |> render_submit()

      assert {:ok, saved} = Listings.get_my_listing(listing.id, actor: seller)
      assert saved.title == "A better title"
      assert saved.status == :active
    end

    test "leaves the first-published stamp where it was", %{
      seller: seller,
      listing: listing,
      view: view
    } do
      view |> form("#listing-form", listing: %{title: "A better title"}) |> render_submit()

      assert {:ok, saved} = Listings.get_my_listing(listing.id, actor: seller)
      assert saved.published_at == listing.published_at
    end
  end

  describe "saving a paused listing" do
    setup %{conn: conn} do
      seller = generate(user())

      paused =
        Listings.pause_listing!(publish!(seller, generate(listing(actor: seller))), actor: seller)

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{paused.id}/edit")

      %{seller: seller, listing: paused, view: view}
    end

    test "saves the change without putting it back on offer", %{
      seller: seller,
      listing: listing,
      view: view
    } do
      view |> form("#listing-form", listing: %{title: "A better title"}) |> render_submit()

      assert {:ok, saved} = Listings.get_my_listing(listing.id, actor: seller)
      assert saved.title == "A better title"
      assert saved.status == :unavailable
    end
  end

  describe "keeping a listing without offering it" do
    setup %{conn: conn} do
      seller = generate(user())
      category = generate(category())
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/new")

      %{seller: seller, category: category, view: view}
    end

    defp finish_later(view, params) do
      view
      |> form("#listing-form", listing: params)
      |> put_submitter("#save-draft")
      |> render_submit()
    end

    test "keeps a new listing as a draft", %{seller: seller, category: category, view: view} do
      finish_later(view, fields(category))

      assert [%{status: :draft, title: "Eames-style lounge chair"}] =
               Listings.list_my_listings!(actor: seller)
    end

    test "says the draft was saved", %{category: category, view: view} do
      finish_later(view, fields(category))

      assert view |> element("#flash-info") |> render() =~ "Draft saved"
    end

    test "carries on editing the draft it just made", %{
      seller: seller,
      category: category,
      view: view
    } do
      finish_later(view, fields(category))

      [listing] = Listings.list_my_listings!(actor: seller)
      assert_patched(view, "/listings/#{listing.id}/edit")
    end

    test "leaves a draft that could have gone on offer as a draft", %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller))
      generate(listing_image(listing: listing))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      view
      |> form("#listing-form", listing: %{title: "A better title"})
      |> put_submitter("#save-draft")
      |> render_submit()

      assert {:ok, saved} = Listings.get_my_listing(listing.id, actor: seller)
      assert saved.status == :draft
      assert saved.title == "A better title"
    end

    test "writes nothing at all when a field is refused", %{
      seller: seller,
      category: category,
      view: view
    } do
      finish_later(view, fields(category, %{title: "ab"}))

      assert Listings.list_my_listings!(actor: seller) == []
    end
  end

  describe "confirming a draft was kept when it could not go on offer" do
    test "says the draft was saved as well as why it is not on offer", %{conn: conn} do
      seller = generate(user())
      category = generate(category())
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/new")

      view |> form("#listing-form", listing: fields(category)) |> render_submit()

      assert view |> element("#flash-info") |> render() =~ "Draft saved"
      assert view |> element("#listing-photos") |> render() =~ "at least #{Listings.min_images()}"
    end
  end

  describe "throwing away changes to a listing on offer" do
    setup %{conn: conn} do
      seller = generate(user())

      listing =
        publish!(seller, generate(listing(actor: seller, title: "Eames-style lounge chair")))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    test "offers throwing them away rather than keeping a draft", %{view: view} do
      html = view |> element("#save-draft") |> render()

      assert html =~ "Discard changes"
      assert html =~ "data-confirm"
    end

    test "puts back what was stored", %{view: view} do
      view
      |> form("#listing-form", listing: %{title: "Something else entirely"})
      |> render_change()

      view |> element("#save-draft") |> render_click()

      assert value(view, "#listing_title") == "Eames-style lounge chair"
    end

    test "changes nothing that was saved", %{seller: seller, listing: listing, view: view} do
      view
      |> form("#listing-form", listing: %{title: "Something else entirely"})
      |> render_change()

      view |> element("#save-draft") |> render_click()

      assert {:ok, saved} = Listings.get_my_listing(listing.id, actor: seller)
      assert saved.title == "Eames-style lounge chair"
    end

    test "says the changes were thrown away", %{view: view} do
      view |> element("#save-draft") |> render_click()

      assert view |> element("#flash-info") |> render() =~ "discarded"
    end
  end

  describe "taking a listing off offer" do
    setup %{conn: conn} do
      seller = generate(user())

      listing =
        publish!(seller, generate(listing(actor: seller, title: "Eames-style lounge chair")))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    test "pauses the listing", %{seller: seller, listing: listing, view: view} do
      view |> element("#pause-listing") |> render_click()

      assert {:ok, paused} = Listings.get_my_listing(listing.id, actor: seller)
      assert paused.status == :unavailable
    end

    test "says so", %{view: view} do
      view |> element("#pause-listing") |> render_click()

      assert view |> element("#flash-info") |> render() =~ "paused"
    end

    test "reads back as paused without leaving the page", %{view: view} do
      view |> element("#pause-listing") |> render_click()

      assert view |> element("#listing-status") |> render() =~ "Paused"
      assert has_element?(view, "#listing-form")
    end

    test "offers no second pause, having nothing left on offer", %{view: view} do
      view |> element("#pause-listing") |> render_click()

      refute has_element?(view, "#pause-listing")
    end

    test "still offers saving changes rather than publishing again", %{view: view} do
      view |> element("#pause-listing") |> render_click()

      assert view |> element("#publish-listing") |> render() =~ "Save changes"
    end

    test "keeps what the seller was still writing", %{view: view} do
      view
      |> form("#listing-form", listing: %{title: "Eames-style lounge chair, walnut"})
      |> render_change()

      view |> element("#pause-listing") |> render_click()

      assert value(view, "#listing_title") == "Eames-style lounge chair, walnut"
    end

    test "keeps the gallery on the page", %{listing: listing, view: view} do
      view |> element("#pause-listing") |> render_click()

      [image] = Listings.list_listing_images!(listing.id, authorize?: false)
      assert has_element?(view, "#photo-#{image.id}")
    end

    test "writes nothing when the listing has already moved on", %{
      seller: seller,
      listing: listing,
      view: view
    } do
      Listings.pause_listing!(listing, actor: seller)

      view |> element("#pause-listing") |> render_click()

      assert view |> element("#flash-error") |> render() =~ "could not be paused"
    end
  end

  describe "adding a photo" do
    setup %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller))
      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    defp upload(view, opts \\ []) do
      name = Keyword.get(opts, :name, "photo.png")

      entry = %{
        name: name,
        content: Keyword.get(opts, :content, Mercato.TestGenerators.png_bytes()),
        type: Keyword.get(opts, :type, "image/png")
      }

      view
      |> file_input("#listing-form", :photos, [entry])
      |> render_upload(name)
    end

    defp gallery(view), do: view |> element("#listing-photos") |> render()

    test "puts it in the listing's gallery", %{listing: listing, view: view} do
      upload(view)

      assert [image] = Listings.list_listing_images!(listing.id, authorize?: false)
      assert has_element?(view, "#photo-#{image.id}")
    end

    test "makes the first photo the cover", %{listing: listing, view: view} do
      upload(view)

      assert [%{is_cover: true}] = Listings.list_listing_images!(listing.id, authorize?: false)
    end

    test "puts a later photo behind the first, leaving the cover alone", %{
      listing: listing,
      view: view
    } do
      upload(view, name: "first.png")
      upload(view, name: "second.png")

      assert [%{is_cover: true, position: 0}, %{is_cover: false, position: 1}] =
               Listings.list_listing_images!(listing.id, authorize?: false)
    end

    test "counts the gallery afresh", %{view: view} do
      upload(view)

      assert gallery(view) =~ "1 of #{Listings.max_images()}"
    end

    test "refuses bytes that are not an image at all", %{listing: listing, view: view} do
      upload(view, content: "this is not an image")

      assert Listings.list_listing_images!(listing.id, authorize?: false) == []
      assert gallery(view) =~ "not an accepted image type"
    end

    test "offers no way to add one past what the gallery holds", %{
      seller: seller,
      listing: listing
    } do
      for _ <- 1..Listings.max_images(), do: generate(listing_image(listing: listing))

      {:ok, view, _html} =
        live(log_in(build_conn(), seller), ~p"/listings/#{listing.id}/edit")

      refute has_element?(view, "#listing-form input[type=file]")
      assert view |> element("#add-photos") |> render() =~ "all #{Listings.max_images()}"
    end
  end

  describe "adding a photo before the listing exists" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(log_in(conn, generate(user())), ~p"/listings/new")

      %{view: view}
    end

    test "offers no way to add one yet", %{view: view} do
      refute has_element?(view, "#listing-form input[type=file]")
    end

    test "says what has to happen first", %{view: view} do
      assert view |> element("#add-photos") |> render() =~ "Save"
    end

    test "still names what the gallery will accept", %{view: view} do
      assert view |> element("#add-photos") |> render() =~ to_string(Listings.max_images())
    end
  end

  describe "removing a photo" do
    setup %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller))
      first = generate(listing_image(listing: listing))
      second = generate(listing_image(listing: listing))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, first: first, second: second, view: view}
    end

    test "takes it out of the gallery", %{listing: listing, second: second, view: view} do
      view |> element("#remove-photo-#{second.id}") |> render_click()

      assert [remaining] = Listings.list_listing_images!(listing.id, authorize?: false)
      assert remaining.id != second.id
      refute has_element?(view, "#photo-#{second.id}")
    end

    test "hands the cover on when the cover is the one removed", %{
      listing: listing,
      first: first,
      second: second,
      view: view
    } do
      view |> element("#remove-photo-#{first.id}") |> render_click()

      assert [%{id: id, is_cover: true}] =
               Listings.list_listing_images!(listing.id, authorize?: false)

      assert id == second.id
    end

    test "refuses to drop a listing on offer below the minimum", %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller))
      image = generate(listing_image(listing: listing))
      Listings.publish_listing!(listing, actor: seller)

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      view |> element("#remove-photo-#{image.id}") |> render_click()

      assert [_still_there] = Listings.list_listing_images!(listing.id, authorize?: false)

      assert view |> element("#listing-photos") |> render() =~
               "fewer than #{Listings.min_images()}"
    end
  end

  describe "promoting a photo to cover" do
    setup %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller))
      first = generate(listing_image(listing: listing))
      second = generate(listing_image(listing: listing))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, first: first, second: second, view: view}
    end

    test "makes it the cover and stands the previous one down", %{
      listing: listing,
      first: first,
      second: second,
      view: view
    } do
      view |> element("#make-cover-#{second.id}") |> render_click()

      images = Listings.list_listing_images!(listing.id, authorize?: false)

      assert Enum.find(images, &(&1.id == second.id)).is_cover
      refute Enum.find(images, &(&1.id == first.id)).is_cover
    end

    test "offers no promotion on the photo that is already the cover", %{
      first: first,
      view: view
    } do
      refute has_element?(view, "#make-cover-#{first.id}")
    end

    test "marks the newly promoted photo in the grid", %{second: second, view: view} do
      view |> element("#make-cover-#{second.id}") |> render_click()

      assert view |> element("#photo-#{second.id}") |> render() =~ "Cover"
    end
  end

  describe "putting a paused listing back on offer" do
    setup %{conn: conn} do
      seller = generate(user())

      paused =
        Listings.pause_listing!(publish!(seller, generate(listing(actor: seller))), actor: seller)

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{paused.id}/edit")

      %{seller: seller, listing: paused, view: view}
    end

    test "puts it back on offer", %{seller: seller, listing: listing, view: view} do
      view |> element("#resume-listing") |> render_click()

      assert {:ok, resumed} = Listings.get_my_listing(listing.id, actor: seller)
      assert resumed.status == :active
    end

    test "says so", %{view: view} do
      view |> element("#resume-listing") |> render_click()

      assert view |> element("#flash-info") |> render() =~ "on offer"
    end

    test "reads back as live without leaving the page", %{view: view} do
      view |> element("#resume-listing") |> render_click()

      assert view |> element("#listing-status") |> render() =~ "Live"
      assert has_element?(view, "#listing-form")
    end

    test "offers pausing again, and no second relist", %{view: view} do
      view |> element("#resume-listing") |> render_click()

      assert has_element?(view, "#pause-listing")
      refute has_element?(view, "#resume-listing")
    end

    test "keeps what the seller was still writing", %{view: view} do
      view
      |> form("#listing-form", listing: %{title: "Eames-style lounge chair, walnut"})
      |> render_change()

      view |> element("#resume-listing") |> render_click()

      assert value(view, "#listing_title") == "Eames-style lounge chair, walnut"
    end

    test "says why it cannot go back on offer without its photos", %{
      seller: seller,
      listing: listing,
      view: view
    } do
      for image <- Listings.list_listing_images!(listing.id, authorize?: false) do
        :ok = Listings.delete_listing_image(image, actor: seller)
      end

      view |> element("#resume-listing") |> render_click()

      assert {:ok, %{status: :unavailable}} = Listings.get_my_listing(listing.id, actor: seller)
      assert view |> element("#listing-photos") |> render() =~ "at least #{Listings.min_images()}"
    end
  end

  describe "relisting is offered only where it can be taken" do
    test "a listing on offer is offered no relist", %{conn: conn} do
      seller = generate(user())
      listing = publish!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      refute has_element?(view, "#resume-listing")
    end

    test "a draft is offered no relist, having never been on offer", %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      refute has_element?(view, "#resume-listing")
    end
  end

  describe "removing a listing from the page it is composed on" do
    setup %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller, title: "Eames-style lounge chair"))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    test "asks before doing it, naming what will go", %{listing: listing, view: view} do
      html = view |> element("#delete-listing") |> render()

      assert html =~ "data-confirm"
      assert html =~ listing.title
    end

    test "takes it off Mercato", %{seller: seller, view: view} do
      view |> element("#delete-listing") |> render_click()

      assert Listings.list_my_listings!(actor: seller) == []
    end

    test "sends the seller back to their own listings, the page being gone", %{view: view} do
      view |> element("#delete-listing") |> render_click()

      assert_redirect(view, "/my-listings")
    end

    test "takes the gallery and its files with it", %{listing: listing, view: view} do
      image = generate(listing_image(listing: listing))

      view |> element("#delete-listing") |> render_click()

      storage = Application.fetch_env!(:mercato, :storage_adapter)
      assert {:error, _gone} = storage.get(image.storage_key)
    end

    test "is offered on a listing already on offer too", %{conn: conn} do
      seller = generate(user())
      listing = publish!(seller, generate(listing(actor: seller)))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      assert has_element?(view, "#delete-listing")
    end

    test "is offered on nothing that has not been saved yet", %{conn: conn} do
      {:ok, view, _html} = live(log_in(conn, generate(user())), ~p"/listings/new")

      refute has_element?(view, "#delete-listing")
    end
  end

  describe "a draft keeping itself" do
    setup %{conn: conn} do
      seller = generate(user())
      listing = generate(listing(actor: seller, title: "Eames-style lounge chair"))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      %{seller: seller, listing: listing, view: view}
    end

    test "saves what the seller types without being asked", %{
      seller: seller,
      listing: listing,
      view: view
    } do
      view
      |> form("#listing-form", listing: %{title: "Eames-style lounge chair, walnut"})
      |> render_change()

      assert {:ok, saved} = Listings.get_my_listing(listing.id, actor: seller)
      assert saved.title == "Eames-style lounge chair, walnut"
    end

    test "leaves it a draft rather than putting it on offer", %{
      seller: seller,
      listing: listing,
      view: view
    } do
      view |> form("#listing-form", listing: %{title: "A better title"}) |> render_change()

      assert {:ok, %{status: :draft}} = Listings.get_my_listing(listing.id, actor: seller)
    end

    test "writes nothing while what was typed is refused", %{
      seller: seller,
      listing: listing,
      view: view
    } do
      view |> form("#listing-form", listing: %{title: "ab"}) |> render_change()

      assert {:ok, saved} = Listings.get_my_listing(listing.id, actor: seller)
      assert saved.title == "Eames-style lounge chair"
    end

    test "says it is keeping itself, so the seller can leave", %{view: view} do
      assert view |> element("#listing-form") |> render() =~ "Saved automatically"
    end

    test "keeps what the seller typed on the page", %{view: view} do
      view |> form("#listing-form", listing: %{title: "A better title"}) |> render_change()

      assert value(view, "#listing_title") == "A better title"
    end
  end

  describe "a listing that keeps itself only when asked" do
    test "one on offer is never saved behind the seller's back", %{conn: conn} do
      seller = generate(user())

      listing =
        publish!(seller, generate(listing(actor: seller, title: "Eames-style lounge chair")))

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{listing.id}/edit")

      view
      |> form("#listing-form", listing: %{title: "Something buyers never chose"})
      |> render_change()

      assert {:ok, saved} = Listings.get_my_listing(listing.id, actor: seller)
      assert saved.title == "Eames-style lounge chair"
      refute view |> element("#listing-form") |> render() =~ "Saved automatically"
    end

    test "a paused one is not saved either, since it goes back on offer as it stands", %{
      conn: conn
    } do
      seller = generate(user())

      paused =
        Listings.pause_listing!(
          publish!(seller, generate(listing(actor: seller, title: "Eames-style lounge chair"))),
          actor: seller
        )

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/#{paused.id}/edit")
      view |> form("#listing-form", listing: %{title: "A better title"}) |> render_change()

      assert {:ok, saved} = Listings.get_my_listing(paused.id, actor: seller)
      assert saved.title == "Eames-style lounge chair"
    end

    test "one not yet saved has nothing to keep itself in", %{conn: conn} do
      seller = generate(user())
      category = generate(category())

      {:ok, view, _html} = live(log_in(conn, seller), ~p"/listings/new")

      view
      |> form("#listing-form",
        listing: %{title: "Eames-style lounge chair", price: "42.00", category_id: category.id}
      )
      |> render_change()

      assert Listings.list_my_listings!(actor: seller) == []
    end
  end
end
