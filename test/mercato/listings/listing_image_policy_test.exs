defmodule Mercato.Listings.ListingImagePolicyTest do
  use Mercato.DataCase, async: false

  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    seller = generate(user())
    listing = generate(listing(actor: seller))
    image = generate(listing_image(listing: listing))

    %{seller: seller, other: generate(user()), listing: listing, image: image}
  end

  describe "seeing a gallery" do
    test "anyone may see the images of a listing on offer", %{
      seller: seller,
      listing: listing,
      other: other,
      image: image
    } do
      {:ok, _} = Listings.publish_listing(listing, actor: seller)

      assert [seen] = Listings.list_listing_images!(listing.id, actor: other)
      assert seen.id == image.id
    end

    test "a draft's images are the seller's alone", %{
      listing: listing,
      other: other,
      seller: seller
    } do
      assert Listings.list_listing_images!(listing.id, actor: other) == []
      assert [_seen] = Listings.list_listing_images!(listing.id, actor: seller)
    end
  end

  describe "changing a gallery" do
    test "the seller may add, promote and remove", %{seller: seller, listing: listing} do
      assert {:ok, second} =
               Listings.add_listing_image(
                 %{listing_id: listing.id, image: png_bytes(), filename: "second.png"},
                 actor: seller
               )

      assert {:ok, _} = Listings.set_listing_image_cover(second, actor: seller)
      assert :ok = Listings.delete_listing_image(second, actor: seller)
    end

    test "nobody else may add to it", %{listing: listing, other: other} do
      assert {:error, %Ash.Error.Forbidden{}} =
               Listings.add_listing_image(
                 %{listing_id: listing.id, image: png_bytes(), filename: "theirs.png"},
                 actor: other
               )
    end

    test "nobody else may promote one to cover", %{seller: seller, listing: listing, other: other} do
      {:ok, _} = Listings.publish_listing(listing, actor: seller)

      second =
        Listings.add_listing_image!(
          %{listing_id: listing.id, image: png_bytes(), filename: "second.png"},
          actor: seller
        )

      assert {:error, %Ash.Error.Forbidden{}} =
               Listings.set_listing_image_cover(second, actor: other)
    end

    test "nobody else may remove one", %{seller: seller, listing: listing, other: other} do
      {:ok, _} = Listings.publish_listing(listing, actor: seller)

      second =
        Listings.add_listing_image!(
          %{listing_id: listing.id, image: png_bytes(), filename: "second.png"},
          actor: seller
        )

      assert {:error, %Ash.Error.Forbidden{}} =
               Listings.delete_listing_image(second, actor: other)
    end
  end
end
