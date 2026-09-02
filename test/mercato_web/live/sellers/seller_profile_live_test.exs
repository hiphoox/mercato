defmodule MercatoWeb.Sellers.SellerProfileLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers
  alias Mercato.Listings

  defp publish!(seller, listing) do
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp sell!(seller, listing) do
    seller |> publish!(listing) |> Listings.mark_listing_sold!(actor: nil)
  end

  defp on_offer!(seller), do: publish!(seller, generate(listing(actor: seller)))
  defp sold!(seller), do: sell!(seller, generate(listing(actor: seller)))

  setup do
    %{seller: generate(user(first_name: "Marta", last_name: "Ribeiro"))}
  end

  describe "reaching the page" do
    test "opens for a visitor with no account", %{conn: conn, seller: seller} do
      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#seller-profile")
    end

    test "names the seller as the page's heading", %{conn: conn, seller: seller} do
      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert view |> element("#seller-name") |> render() =~ "Marta Ribeiro"
    end

    test "shows the handle the profile is addressed by", %{conn: conn, seller: seller} do
      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert view |> element("#seller-handle") |> render() =~ "@#{seller.handle}"
    end

    test "says nothing exists at a handle nobody holds", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/nobody_at_all")

      assert has_element?(view, "#seller-gone")
      refute has_element?(view, "#seller-profile")
    end

    test "says nothing exists at a banned seller's handle either", %{conn: conn, seller: seller} do
      on_offer!(seller)
      admin = admin_user() |> grant_permission("user:update")
      Mercato.Accounts.change_status!(seller, :banned, actor: admin)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#seller-gone")
      refute has_element?(view, "#seller-profile")
    end

    test "trails one level, since a seller sits under nothing", %{conn: conn, seller: seller} do
      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "nav[aria-label='Breadcrumb']")
    end
  end

  describe "what the page lists" do
    test "shows a listing on offer", %{conn: conn, seller: seller} do
      listing = on_offer!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#on-offer-listing-#{listing.id}")
    end

    test "shows a sold listing below the ones on offer", %{conn: conn, seller: seller} do
      on_offer = on_offer!(seller)
      sold = sold!(seller)

      {:ok, view, html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#sold-listing-#{sold.id}")

      {on_offer_at, _} = :binary.match(html, ~s(id="on-offer-listing-#{on_offer.id}"))
      {sold_at, _} = :binary.match(html, ~s(id="sold-listing-#{sold.id}"))
      assert on_offer_at < sold_at
    end

    test "opens a listing on offer, and leads nowhere from a sold one", %{
      conn: conn,
      seller: seller
    } do
      on_offer = on_offer!(seller)
      sold = sold!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#on-offer-listing-#{on_offer.id} a")
      refute has_element?(view, "#sold-listing-#{sold.id} a")
    end

    test "leaves out a draft", %{conn: conn, seller: seller} do
      draft = generate(listing(actor: seller))

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      refute has_element?(view, "#on-offer-listing-#{draft.id}")
      refute has_element?(view, "#sold-listing-#{draft.id}")
    end

    test "leaves out a paused listing", %{conn: conn, seller: seller} do
      paused = Listings.pause_listing!(on_offer!(seller), actor: seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      refute has_element?(view, "#on-offer-listing-#{paused.id}")
    end

    test "counts what is on offer and what has sold", %{conn: conn, seller: seller} do
      on_offer!(seller)
      on_offer!(seller)
      sold!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert view |> element("#count-on-offer") |> render() =~ "2"
      assert view |> element("#count-sold") |> render() =~ "1"
    end

    test "shows the seller their own profile as a visitor sees it", %{
      conn: conn,
      seller: seller
    } do
      draft = generate(listing(actor: seller))
      on_offer = on_offer!(seller)

      {:ok, view, _html} =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Helpers.store_in_session(seller)
        |> live(~p"/users/#{seller.handle}")

      assert has_element?(view, "#on-offer-listing-#{on_offer.id}")
      refute has_element?(view, "#on-offer-listing-#{draft.id}")
    end
  end

  describe "states the page comes to rest in" do
    test "a seller with nothing either way gets one calm empty state", %{
      conn: conn,
      seller: seller
    } do
      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#seller-has-nothing")
      refute has_element?(view, "#sold-section")
    end

    test "a seller who has sold nothing yet gets no sold section at all", %{
      conn: conn,
      seller: seller
    } do
      on_offer!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      refute has_element?(view, "#sold-section")
    end

    test "a seller whose stock has all sold is told so, rather than shown an absence", %{
      conn: conn,
      seller: seller
    } do
      sold!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#everything-sold")
      assert has_element?(view, "#sold-section")
      refute has_element?(view, "#seller-has-nothing")
    end
  end

  describe "the sold history" do
    test "caps the sold grid and offers the rest", %{conn: conn, seller: seller} do
      for _ <- 1..5, do: sold!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert view |> element("#sold-section") |> render() |> sold_cards() == 4
      assert has_element?(view, "#show-all-sold")
    end

    test "opens the rest in place", %{conn: conn, seller: seller} do
      for _ <- 1..5, do: sold!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      html = view |> element("#show-all-sold") |> render_click()

      assert sold_cards(html) == 5
      refute has_element?(view, "#show-all-sold")
    end

    test "offers nothing to expand when the whole history fits", %{conn: conn, seller: seller} do
      for _ <- 1..3, do: sold!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      refute has_element?(view, "#show-all-sold")
    end
  end

  defp sold_cards(html) do
    html |> LazyHTML.from_fragment() |> LazyHTML.query("[id^='sold-listing-']") |> Enum.count()
  end

  describe "adding a seller's listing to a cart" do
    test "offers the action on what is on offer", %{conn: conn, seller: seller} do
      listing = on_offer!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#on-offer-listing-#{listing.id} #add-to-cart-#{listing.id}")
    end

    test "leaves it off a sold listing, which is a record rather than an offer", %{
      conn: conn,
      seller: seller
    } do
      sold = sold!(seller)

      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#sold-listing-#{sold.id}")
      refute has_element?(view, "#add-to-cart-#{sold.id}")
    end

    # The page is otherwise the same for its owner as for a stranger, so it can
    # be used to check what buyers see. The one control that goes is the one
    # that would be refused: nobody buys from themselves.
    test "leaves it off the seller's own storefront", %{conn: conn, seller: seller} do
      listing = on_offer!(seller)

      conn = conn |> Plug.Test.init_test_session(%{}) |> Helpers.store_in_session(seller)
      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#on-offer-listing-#{listing.id}")
      refute has_element?(view, "#add-to-cart-#{listing.id}")
    end

    test "keeps offering it on somebody else's storefront", %{conn: conn, seller: seller} do
      listing = on_offer!(seller)
      buyer = generate(user())

      conn = conn |> Plug.Test.init_test_session(%{}) |> Helpers.store_in_session(buyer)
      {:ok, view, _html} = live(conn, ~p"/users/#{seller.handle}")

      assert has_element?(view, "#add-to-cart-#{listing.id}")
    end
  end
end
