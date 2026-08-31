defmodule Mercato.Listings.ListingBrowseFacetsTest do
  use Mercato.DataCase, async: false

  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    %{seller: generate(user())}
  end

  defp on_offer!(seller, opts \\ []) do
    listing = generate(listing(Keyword.put(opts, :actor, seller)))
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp ids(filters) do
    %{filters: filters} |> Listings.browse_listings!() |> Enum.map(& &1.id) |> Enum.sort()
  end

  describe "a select facet reaching across a relationship" do
    setup %{seller: seller} do
      furniture = generate(category(name: "Furniture", slug: "furniture"))
      bikes = generate(category(name: "Bikes", slug: "bikes"))

      %{
        chair: on_offer!(seller, category_id: furniture.id),
        bike: on_offer!(seller, category_id: bikes.id)
      }
    end

    test "keeps only what is filed under the category named", %{chair: chair} do
      assert ids(%{category: "furniture"}) == [chair.id]
    end

    test "narrows by nothing where the facet is left unstated", %{chair: chair, bike: bike} do
      assert ids(%{}) == Enum.sort([chair.id, bike.id])
    end

    test "reads an empty value as no narrowing", %{chair: chair, bike: bike} do
      assert ids(%{category: ""}) == Enum.sort([chair.id, bike.id])
    end

    test "empties the grid for a category nothing is filed under" do
      assert ids(%{category: "harpsichords"}) == []
    end
  end

  describe "a select facet on the listing itself" do
    setup %{seller: seller} do
      %{
        good: on_offer!(seller, condition: "good"),
        fair: on_offer!(seller, condition: "fair")
      }
    end

    test "keeps only what is in the condition named", %{good: good} do
      assert ids(%{condition: "good"}) == [good.id]
    end

    test "empties the grid for a condition nothing is in" do
      assert ids(%{condition: "like_new"}) == []
    end
  end

  describe "a range facet" do
    setup %{seller: seller} do
      %{
        cheap: on_offer!(seller, price: 1_000),
        mid: on_offer!(seller, price: 5_000),
        dear: on_offer!(seller, price: 9_000)
      }
    end

    test "keeps what costs at least the floor stated", %{mid: mid, dear: dear} do
      assert ids(%{price: %{min: 5_000}}) == Enum.sort([mid.id, dear.id])
    end

    test "keeps what costs at most the ceiling stated", %{cheap: cheap, mid: mid} do
      assert ids(%{price: %{max: 5_000}}) == Enum.sort([cheap.id, mid.id])
    end

    test "keeps what falls between both ends", %{mid: mid} do
      assert ids(%{price: %{min: 2_000, max: 8_000}}) == [mid.id]
    end

    test "narrows by nothing where both ends are left open", %{
      cheap: cheap,
      mid: mid,
      dear: dear
    } do
      assert ids(%{price: %{min: nil, max: nil}}) == Enum.sort([cheap.id, mid.id, dear.id])
    end
  end

  describe "facets stated together" do
    test "narrows by every one of them at once", %{seller: seller} do
      furniture = generate(category(name: "Furniture", slug: "furniture"))

      wanted = on_offer!(seller, category_id: furniture.id, condition: "good", price: 5_000)
      on_offer!(seller, category_id: furniture.id, condition: "fair", price: 5_000)
      on_offer!(seller, category_id: furniture.id, condition: "good", price: 90_000)

      assert ids(%{category: "furniture", condition: "good", price: %{max: 10_000}}) == [
               wanted.id
             ]
    end

    test "narrows alongside a search term", %{seller: seller} do
      wanted = on_offer!(seller, title: "Walnut chair", price: 5_000)
      on_offer!(seller, title: "Walnut table", price: 5_000)
      on_offer!(seller, title: "Walnut chair", price: 90_000)

      found =
        Listings.browse_listings!(%{query: "chair", filters: %{price: %{max: 10_000}}})

      assert Enum.map(found, & &1.id) == [wanted.id]
    end
  end

  describe "a filter this marketplace does not offer" do
    test "is ignored rather than raising, so a stale link still lands on the grid", %{
      seller: seller
    } do
      listing = on_offer!(seller)

      assert ids(%{mileage: "120000"}) == [listing.id]
    end
  end

  describe "the facets the marketplace configures" do
    test "decide what the grid can be narrowed by", %{seller: seller} do
      good = on_offer!(seller, condition: "good", price: 90_000)
      fair = on_offer!(seller, condition: "fair", price: 90_000)

      Application.put_env(:mercato, :browse_facets, [
        [key: :condition, kind: :select, field: :condition, label: "Condition"]
      ])

      on_exit(fn -> Application.delete_env(:mercato, :browse_facets) end)

      assert ids(%{condition: "good"}) == [good.id]

      # Price is no longer offered, so a bound stated against it narrows
      # nothing rather than emptying the grid.
      assert ids(%{price: %{max: 1}}) == Enum.sort([good.id, fair.id])
    end
  end
end
