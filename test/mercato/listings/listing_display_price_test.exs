defmodule Mercato.Listings.ListingDisplayPriceTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  describe "display_price" do
    test "renders the listing's own price and currency" do
      seller = generate(user())
      generate(listing(actor: seller, price: 42_000))

      assert [%{display_price: "$420.00"}] = Listings.list_my_listings!(actor: seller)
    end

    test "comes loaded, so a caller never formats a price itself" do
      seller = generate(user())
      generate(listing(actor: seller, price: 1805))

      [listing] = Listings.list_my_listings!(actor: seller)

      refute match?(%Ash.NotLoaded{}, listing.display_price)
      assert listing.display_price == "$18.05"
    end
  end
end
