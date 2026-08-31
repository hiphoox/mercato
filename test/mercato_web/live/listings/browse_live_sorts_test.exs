defmodule MercatoWeb.Listings.BrowseLiveSortsTest do
  @moduledoc """
  The browse page on a marketplace that declares its own orders rather than the
  ones shipped by default — the case the declarations exist for.
  """

  # Not async: the declared set is application state, and swapping it would
  # otherwise be seen by every test running alongside.
  use MercatoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    original = Application.get_env(:mercato, :browse_sorts)

    on_exit(fn ->
      case original do
        nil -> Application.delete_env(:mercato, :browse_sorts)
        declared -> Application.put_env(:mercato, :browse_sorts, declared)
      end
    end)

    %{seller: generate(user())}
  end

  defp declare(sorts), do: Application.put_env(:mercato, :browse_sorts, sorts)

  defp on_offer!(seller, opts) do
    listing = generate(listing(Keyword.put(opts, :actor, seller)))
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp titles(view) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("[id^='browse-listing-'] h3")
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end

  describe "a marketplace declaring its own orders" do
    setup %{seller: seller} do
      declare([
        [key: :title, label: "A to Z", by: [title: :asc]],
        [key: :dearest, label: "Most expensive", by: [price: :desc]]
      ])

      # Priced so the two declared orders disagree: by title the armchair leads,
      # by price the bicycle does. An assertion that cannot tell them apart
      # would pass whichever order was actually in force.
      on_offer!(seller, title: "Bicycle", price: 90_000)
      on_offer!(seller, title: "Armchair", price: 5_000)

      :ok
    end

    test "offers those orders and no other", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse-sort-title", "A to Z")
      assert has_element?(view, "#browse-sort-dearest", "Most expensive")
      refute has_element?(view, "#browse-sort-price_asc")
      refute has_element?(view, "#browse-sort-newest")
    end

    test "words an order the way the marketplace worded it", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert view |> element("#browse-sort-trigger") |> render() =~ "A to Z"
    end

    test "reads the shelf in the first order declared when none is asked for", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert titles(view) == ["Armchair", "Bicycle"]
    end

    test "reads the shelf in an order asked for by name", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?sort=dearest")

      assert titles(view) == ["Bicycle", "Armchair"]
    end

    test "keeps the default order out of the address", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?sort=dearest")

      view |> element("#browse-sort-title") |> render_click()

      assert_patched(view, "/")
    end

    test "falls back to the grid for an order it no longer offers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?sort=price_asc")

      assert titles(view) == ["Armchair", "Bicycle"]
      assert view |> element("#browse-sort-trigger") |> render() =~ "A to Z"
    end
  end

  describe "an order that settles its ties" do
    test "falls back to the first declared order for two rows that tie", %{seller: seller} do
      declare([
        [key: :title, label: "A to Z", by: [title: :asc]],
        [key: :cheapest, label: "Cheapest", by: [price: :asc]]
      ])

      on_offer!(seller, title: "Bicycle", price: 5_000)
      on_offer!(seller, title: "Armchair", price: 5_000)

      found = Listings.browse_listings!(%{sort: :cheapest})

      assert Enum.map(found, & &1.title) == ["Armchair", "Bicycle"]
    end
  end
end
