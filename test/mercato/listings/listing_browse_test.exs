defmodule Mercato.Listings.ListingBrowseTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    %{seller: generate(user())}
  end

  defp publish!(seller, listing) do
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp on_offer!(seller), do: publish!(seller, generate(listing(actor: seller)))

  describe "browse_listings" do
    test "returns a listing on offer", %{seller: seller} do
      listing = on_offer!(seller)

      assert [found] = Listings.browse_listings!()
      assert found.id == listing.id
    end

    test "reads without an actor, since browsing is public", %{seller: seller} do
      on_offer!(seller)

      assert [_listing] = Listings.browse_listings!(actor: nil)
    end

    test "gathers every seller's listings, not one seller's", %{seller: seller} do
      other = generate(user())
      on_offer!(seller)
      on_offer!(other)

      assert length(Listings.browse_listings!()) == 2
    end

    test "puts the most recently published first", %{seller: seller} do
      first = on_offer!(seller)
      second = on_offer!(seller)
      third = on_offer!(seller)

      assert Enum.map(Listings.browse_listings!(), & &1.id) == [third.id, second.id, first.id]
    end

    test "leaves out a draft, which was never put in front of buyers", %{seller: seller} do
      generate(listing(actor: seller))

      assert Listings.browse_listings!() == []
    end

    test "leaves out a paused listing, which the seller took out of view", %{seller: seller} do
      seller |> on_offer!() |> Listings.pause_listing!(actor: seller)

      assert Listings.browse_listings!() == []
    end

    test "leaves out a sold listing, which is no longer on offer", %{seller: seller} do
      seller |> on_offer!() |> Listings.mark_listing_sold!(actor: nil)

      assert Listings.browse_listings!() == []
    end

    test "leaves out a listing whose seller is off the marketplace", %{seller: seller} do
      on_offer!(seller)
      admin = admin_user() |> grant_permission("user:update")
      Mercato.Accounts.change_status!(seller, :banned, actor: admin)

      assert Listings.browse_listings!() == []
    end

    test "hides the acting seller's own draft, unlike their own listings page", %{seller: seller} do
      generate(listing(actor: seller))

      assert Listings.browse_listings!(actor: seller) == []
    end

    test "loads what a card draws: the formatted price, the gallery and the seller", %{
      seller: seller
    } do
      on_offer!(seller)

      assert [listing] = Listings.browse_listings!()
      assert listing.display_price =~ "10.00"
      assert [%{url: url}] = listing.images
      assert is_binary(url)
      assert listing.seller.handle == seller.handle
    end
  end
end
