defmodule MercatoWeb.Listings.BrowseLiveFacetsTest do
  @moduledoc """
  The browse page on a marketplace that declares its own facets rather than the
  ones shipped by default — the case the declarations exist for.
  """

  # Not async: the declared set is application state, and swapping it would
  # otherwise be seen by every test running alongside.
  use MercatoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    original = Application.get_env(:mercato, :browse_facets)

    on_exit(fn ->
      case original do
        nil -> Application.delete_env(:mercato, :browse_facets)
        declared -> Application.put_env(:mercato, :browse_facets, declared)
      end
    end)

    seller = generate(user())

    %{seller: seller}
  end

  defp declare(facets), do: Application.put_env(:mercato, :browse_facets, facets)

  defp on_offer!(seller, opts) do
    listing = generate(listing(Keyword.put(opts, :actor, seller)))
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  describe "a marketplace declaring no facets at all" do
    test "browses a shelf with nothing to narrow it", %{conn: conn, seller: seller} do
      declare([])
      on_offer!(seller, title: "An hour of tutoring")

      {:ok, view, _html} = live(conn, ~p"/")

      assert render(view) =~ "An hour of tutoring"
      refute has_element?(view, "#browse-sheet-category")
      refute has_element?(view, "#browse-sheet-condition")
      refute has_element?(view, "#browse-price-trigger")
    end

    test "ignores a facet asked for by hand, since none are offered", %{
      conn: conn,
      seller: seller
    } do
      declare([])
      on_offer!(seller, title: "An hour of tutoring", condition: "good")

      {:ok, view, _html} = live(conn, ~p"/?condition=fair")

      assert render(view) =~ "An hour of tutoring"
      refute has_element?(view, "#browse-chip-condition")
    end
  end

  describe "a marketplace declaring only the facets its catalog has" do
    setup do
      declare([
        [
          key: :condition,
          kind: :select,
          field: :condition,
          label: "Condition",
          options: {Mercato.Listings, :condition_options, []}
        ]
      ])
    end

    test "offers that facet and no other", %{conn: conn, seller: seller} do
      on_offer!(seller, condition: "good")

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse-sheet-condition")
      refute has_element?(view, "#browse-sheet-category")
      refute has_element?(view, "#browse-sheet-price-form")
    end

    test "draws it on the bar, since a facet declares where it belongs", %{
      conn: conn,
      seller: seller
    } do
      on_offer!(seller, condition: "good")

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse-condition-trigger")
    end

    test "narrows the grid by it", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Boxed camera", condition: "new")
      on_offer!(seller, title: "Battered camera", condition: "fair")

      {:ok, view, _html} = live(conn, ~p"/?condition=new")

      assert render(view) =~ "Boxed camera"
      refute render(view) =~ "Battered camera"
      assert has_element?(view, "#browse-chip-condition")
    end

    test "leaves a facet it no longer declares out of the address", %{
      conn: conn,
      seller: seller
    } do
      on_offer!(seller, title: "Boxed camera", condition: "new", price: 90_000)

      {:ok, view, _html} = live(conn, ~p"/?price_max=1")

      assert render(view) =~ "Boxed camera"
      refute has_element?(view, "#browse-chip-price")
    end
  end

  describe "a marketplace declaring a facet this codebase has never heard of" do
    setup %{seller: seller} do
      declare([
        [
          key: :listed_price,
          kind: :range,
          field: :price,
          label: "Asking price",
          placement: :sheet
        ]
      ])

      on_offer!(seller, title: "Cheap bike", price: 1_000)
      on_offer!(seller, title: "Dear bike", price: 90_000)

      :ok
    end

    test "words it the way the marketplace worded it", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#browse-filters-sheet", "Asking price")
    end

    test "states it in the address under its own name", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#browse-sheet-listed_price-form", %{"listed_price_max" => "50"})
      |> render_submit()

      assert_patched(view, "/?listed_price_max=50")
    end

    # No parse of its own, so its bounds are the units the column stores rather
    # than the ones a price is typed in — which is what a facet declaring a
    # parse is for.
    test "narrows the grid by it, in the units it declared no reading for", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?listed_price_max=5000")

      assert render(view) =~ "Cheap bike"
      refute render(view) =~ "Dear bike"
    end
  end
end
