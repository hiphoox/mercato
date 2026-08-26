defmodule Mercato.Listings.ListingListForSellerTest do
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

  defp sell!(seller, listing) do
    seller |> publish!(listing) |> Listings.mark_listing_sold!(actor: nil)
  end

  describe "list_seller_listings" do
    test "returns the seller's listings on offer", %{seller: seller} do
      listing = publish!(seller, generate(listing(actor: seller)))

      assert [found] = Listings.list_seller_listings!(seller.id)
      assert found.id == listing.id
    end

    test "returns the seller's sold listings, which the detail page hides", %{seller: seller} do
      sell!(seller, generate(listing(actor: seller)))

      assert [%{status: :sold}] = Listings.list_seller_listings!(seller.id)
    end

    test "leaves out a draft", %{seller: seller} do
      generate(listing(actor: seller))

      assert Listings.list_seller_listings!(seller.id) == []
    end

    test "leaves out a paused listing, which the seller took out of public view", %{
      seller: seller
    } do
      listing = publish!(seller, generate(listing(actor: seller)))
      Listings.pause_listing!(listing, actor: seller)

      assert Listings.list_seller_listings!(seller.id) == []
    end

    test "shows the seller their own profile exactly as a visitor sees it", %{seller: seller} do
      generate(listing(actor: seller))
      publish!(seller, generate(listing(actor: seller)))

      assert [%{status: :active}] = Listings.list_seller_listings!(seller.id, actor: seller)
    end

    test "leaves out another seller's listings", %{seller: seller} do
      other = generate(user())
      publish!(other, generate(listing(actor: other)))

      assert Listings.list_seller_listings!(seller.id) == []
    end

    test "reads without an actor, since the profile is public", %{seller: seller} do
      publish!(seller, generate(listing(actor: seller)))

      assert [_on_offer] = Listings.list_seller_listings!(seller.id, actor: nil)
    end

    test "hands back the gallery and the formatted price, so a card can be drawn", %{
      seller: seller
    } do
      listing = generate(listing(actor: seller))
      image = generate(listing_image(listing: listing))
      Listings.publish_listing!(listing, actor: seller)

      assert [found] = Listings.list_seller_listings!(seller.id)
      assert [%{id: image_id}] = found.images
      assert image_id == image.id
      assert found.display_price == "$10.00"
    end
  end
end
