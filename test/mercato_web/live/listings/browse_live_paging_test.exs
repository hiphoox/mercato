defmodule MercatoWeb.Listings.BrowseLivePagingTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias Mercato.Listings

  defp on_offer!(seller, opts) do
    listing = generate(listing(Keyword.put(opts, :actor, seller)))
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  # Priced apart and read cheapest first, so which listing lands on which page
  # is settled by the data rather than by how fast the rows were written.
  defp shelf!(seller, count) do
    for index <- 1..count do
      on_offer!(seller, title: "Chair number #{index}", price: index * 100)
    end
  end

  defp cards(view) do
    view |> render() |> LazyHTML.from_fragment() |> LazyHTML.query("[id^='browse-listing-']")
  end

  setup do
    %{seller: generate(user())}
  end

  describe "a shelf longer than one page" do
    setup %{seller: seller} do
      %{listings: shelf!(seller, 25)}
    end

    test "draws a page of cards rather than the whole shelf", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?sort=price_asc")

      assert view |> cards() |> Enum.count() == 24
    end

    test "offers the pages the rest of the shelf is on", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?sort=price_asc")

      assert has_element?(view, "nav[aria-label='Pagination'] [data-role='page']", "2")
    end

    test "carries on where the first page left off", %{conn: conn, listings: listings} do
      last = List.last(listings)

      {:ok, view, _html} = live(conn, ~p"/?sort=price_asc&page=2")

      assert has_element?(view, "#browse-listing-#{last.id}")
      assert view |> cards() |> Enum.count() == 1
    end

    test "leaves the first page's listings behind on the second", %{
      conn: conn,
      listings: listings
    } do
      first = List.first(listings)

      {:ok, view, _html} = live(conn, ~p"/?sort=price_asc&page=2")

      refute has_element?(view, "#browse-listing-#{first.id}")
    end

    test "counts every match in the heading, not the page in front of you", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/?q=Chair")

      assert html =~ "25 results"
    end
  end

  describe "a shelf that fits" do
    test "offers no pages to step through where there is only one", %{conn: conn, seller: seller} do
      shelf!(seller, 3)

      {:ok, view, _html} = live(conn, ~p"/")

      refute has_element?(view, "[data-role='next']")
      refute has_element?(view, "[data-role='page']")
    end

    test "still says how much is on the shelf", %{conn: conn, seller: seller} do
      shelf!(seller, 3)

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "[data-role='summary']")
    end

    test "says nothing at all where the marketplace is empty", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      refute has_element?(view, "nav[aria-label='Pagination']")
    end
  end

  describe "a page that is not there" do
    test "lands on the first page when the number runs past the end", %{
      conn: conn,
      seller: seller
    } do
      shelf!(seller, 3)

      {:ok, view, _html} = live(conn, ~p"/?page=999")

      assert view |> cards() |> Enum.count() == 3
    end

    test "lands on the first page when the number is not one", %{conn: conn, seller: seller} do
      shelf!(seller, 3)

      {:ok, view, _html} = live(conn, ~p"/?page=banana")

      assert view |> cards() |> Enum.count() == 3
    end
  end

  describe "paging and the facets" do
    test "keeps the facets in force when stepping to the next page", %{
      conn: conn,
      seller: seller
    } do
      shelf!(seller, 25)

      {:ok, view, _html} = live(conn, ~p"/?q=Chair&sort=price_asc")

      href =
        view
        |> render()
        |> LazyHTML.from_fragment()
        |> LazyHTML.query("nav[aria-label='Pagination'] a[data-role='next']")
        |> LazyHTML.attribute("href")
        |> List.first()

      assert href =~ "q=Chair"
      assert href =~ "sort=price_asc"
      assert href =~ "page=2"
    end

    test "returns to the first page when a filter changes", %{conn: conn, seller: seller} do
      shelf!(seller, 25)

      {:ok, view, _html} = live(conn, ~p"/?sort=price_asc&page=2")

      assert view
             |> element("#browse-sort-price_desc")
             |> render_click()
             |> LazyHTML.from_fragment()
             |> LazyHTML.query("[id^='browse-listing-']")
             |> Enum.count() == 24
    end

    test "drops the page from the address of the first page", %{conn: conn, seller: seller} do
      shelf!(seller, 25)

      {:ok, view, _html} = live(conn, ~p"/?page=2")

      href =
        view
        |> render()
        |> LazyHTML.from_fragment()
        |> LazyHTML.query("nav[aria-label='Pagination'] a[data-role='prev']")
        |> LazyHTML.attribute("href")
        |> List.first()

      assert href == "/"
    end
  end
end
