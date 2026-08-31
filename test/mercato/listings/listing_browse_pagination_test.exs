defmodule Mercato.Listings.ListingBrowsePaginationTest do
  use Mercato.DataCase, async: true

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

  defp ids(page), do: Enum.map(page.results, & &1.id)

  describe "browse_listings paging" do
    test "hands back only as many listings as the page asks for", %{seller: seller} do
      for _ <- 1..5, do: on_offer!(seller)

      page = Listings.browse_listings!(%{}, page: [limit: 2, count: true])

      assert length(page.results) == 2
    end

    test "counts every match, not the ones on the page", %{seller: seller} do
      for _ <- 1..5, do: on_offer!(seller)

      page = Listings.browse_listings!(%{}, page: [limit: 2, count: true])

      assert page.count == 5
    end

    test "walks the order it is read in without repeating or skipping", %{seller: seller} do
      for _ <- 1..5, do: on_offer!(seller)

      whole = Listings.browse_listings!() |> Enum.map(& &1.id)

      walked =
        Enum.flat_map(0..4//2, fn offset ->
          ids(Listings.browse_listings!(%{}, page: [limit: 2, offset: offset]))
        end)

      assert walked == whole
    end

    test "pages what the filters left, not the whole shelf", %{seller: seller} do
      for _ <- 1..3, do: on_offer!(seller, title: "kept #{System.unique_integer([:positive])}")
      for _ <- 1..3, do: on_offer!(seller, title: "dropped #{System.unique_integer([:positive])}")

      page = Listings.browse_listings!(%{query: "kept"}, page: [limit: 2, count: true])

      assert page.count == 3
      assert length(page.results) == 2
    end

    test "runs off the end into an empty page rather than an error", %{seller: seller} do
      on_offer!(seller)

      page = Listings.browse_listings!(%{}, page: [limit: 2, offset: 40, count: true])

      assert page.results == []
      assert page.count == 1
    end

    test "still reads as a plain list when nothing asks for a page", %{seller: seller} do
      for _ <- 1..3, do: on_offer!(seller)

      assert length(Listings.browse_listings!()) == 3
    end
  end
end
