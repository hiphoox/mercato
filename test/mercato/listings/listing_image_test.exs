defmodule Mercato.Listings.ListingImageTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    %{listing: generate(listing())}
  end

  describe "add_listing_image/2" do
    test "stores the key the image was uploaded under", %{listing: listing} do
      assert {:ok, image} = add_image(listing, "listings/abc/photo.jpg")

      assert image.storage_key == "listings/abc/photo.jpg"
      assert image.listing_id == listing.id
    end

    test "requires a storage key", %{listing: listing} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.add_listing_image(%{listing_id: listing.id}, authorize?: false)
    end

    test "requires a listing" do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.add_listing_image(%{storage_key: "orphan.jpg"}, authorize?: false)
    end

    test "stamps the created timestamp", %{listing: listing} do
      assert %DateTime{} = add_image!(listing).created_at
    end
  end

  describe "position" do
    test "puts the first image at the front", %{listing: listing} do
      assert add_image!(listing).position == 0
    end

    test "appends each later image behind the ones already there", %{listing: listing} do
      add_image!(listing)

      assert add_image!(listing).position == 1
      assert add_image!(listing).position == 2
    end

    test "counts only the listing's own images", %{listing: listing} do
      add_image!(listing)

      assert add_image!(generate(listing())).position == 0
    end

    test "goes behind the images left after a delete", %{listing: listing} do
      add_image!(listing)
      second = add_image!(listing)

      :ok = Listings.delete_listing_image(second, authorize?: false)

      assert add_image!(listing).position == 1
    end
  end

  describe "cover" do
    test "makes the first image the cover", %{listing: listing} do
      assert add_image!(listing).is_cover
    end

    test "leaves a later image out of the cover slot", %{listing: listing} do
      add_image!(listing)

      refute add_image!(listing).is_cover
    end

    test "promoting an image demotes the one it replaces", %{listing: listing} do
      first = add_image!(listing)
      second = add_image!(listing)

      assert {:ok, second} = Listings.set_listing_image_cover(second, authorize?: false)

      assert second.is_cover
      refute reload(first).is_cover
    end

    test "promoting the image already covering leaves it covering", %{listing: listing} do
      first = add_image!(listing)

      assert {:ok, first} = Listings.set_listing_image_cover(first, authorize?: false)

      assert first.is_cover
    end

    test "promoting does not touch another listing's cover", %{listing: listing} do
      other_cover = add_image!(generate(listing()))
      add_image!(listing)
      second = add_image!(listing)

      {:ok, _} = Listings.set_listing_image_cover(second, authorize?: false)

      assert reload(other_cover).is_cover
    end

    test "deleting the cover promotes the image behind it", %{listing: listing} do
      cover = add_image!(listing)
      second = add_image!(listing)

      :ok = Listings.delete_listing_image(cover, authorize?: false)

      assert reload(second).is_cover
    end

    test "deleting promotes even when the caller's copy predates the promotion",
         %{listing: listing} do
      first = add_image!(listing)
      second = add_image!(listing)

      # `second` was read before it covered, so its copy still says it does not.
      {:ok, _} = Listings.set_listing_image_cover(second, authorize?: false)

      :ok = Listings.delete_listing_image(second, authorize?: false)

      assert reload(first).is_cover
    end

    test "deleting an image that is not the cover leaves the cover alone", %{listing: listing} do
      cover = add_image!(listing)
      second = add_image!(listing)

      :ok = Listings.delete_listing_image(second, authorize?: false)

      assert reload(cover).is_cover
    end

    test "is refused a second time by the database itself", %{listing: listing} do
      cover = add_image!(listing)

      # Seeded past the actions, which would have prevented this on their own —
      # the point is that the constraint holds even when they are bypassed.
      assert_raise Ash.Error.Invalid, ~r/listing_id: has already been taken/, fn ->
        Ash.Seed.seed!(Mercato.Listings.ListingImage, %{
          listing_id: cover.listing_id,
          storage_key: "second-cover.jpg",
          position: 1,
          is_cover: true
        })
      end
    end

    test "deleting the only image leaves the listing with none", %{listing: listing} do
      only = add_image!(listing)

      :ok = Listings.delete_listing_image(only, authorize?: false)

      assert Listings.list_listing_images!(listing.id, authorize?: false) == []
    end
  end

  describe "list_listing_images/2" do
    test "returns the listing's images in gallery order", %{listing: listing} do
      first = add_image!(listing)
      second = add_image!(listing)
      third = add_image!(listing)

      assert Listings.list_listing_images!(listing.id, authorize?: false)
             |> Enum.map(& &1.id) == [first.id, second.id, third.id]
    end

    test "returns nothing for a listing with no images", %{listing: listing} do
      add_image!(generate(listing()))

      assert Listings.list_listing_images!(listing.id, authorize?: false) == []
    end
  end

  describe "listing relationship" do
    test "a listing has many images in gallery order", %{listing: listing} do
      first = add_image!(listing)
      second = add_image!(listing)

      listing = Ash.load!(listing, :images, authorize?: false)

      assert Enum.map(listing.images, & &1.id) == [first.id, second.id]
    end

    test "an image belongs to its listing", %{listing: listing} do
      image = listing |> add_image!() |> Ash.load!(:listing, authorize?: false)

      assert image.listing.id == listing.id
    end
  end

  defp add_image(listing, storage_key) do
    storage_key = storage_key || "listings/#{listing.id}/#{Ash.UUID.generate()}.jpg"

    Listings.add_listing_image(%{listing_id: listing.id, storage_key: storage_key},
      authorize?: false
    )
  end

  defp add_image!(listing, storage_key \\ nil) do
    {:ok, image} = add_image(listing, storage_key)

    image
  end

  defp reload(image), do: Ash.reload!(image, authorize?: false)
end
