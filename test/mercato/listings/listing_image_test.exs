defmodule Mercato.Listings.ListingImageTest do
  use Mercato.DataCase, async: false

  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    %{listing: generate(listing())}
  end

  describe "add_listing_image/2" do
    test "puts the file in storage and records the key it went to", %{listing: listing} do
      assert {:ok, image} = add_image(listing, filename: "photo.png")

      assert image.listing_id == listing.id
      assert image.storage_key =~ "photo.png"
      assert {:ok, bytes} = storage().get(image.storage_key)
      assert bytes == png_bytes()
    end

    test "requires a name to store the file under", %{listing: listing} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.add_listing_image(%{listing_id: listing.id, image: png_bytes()},
                 authorize?: false
               )
    end

    test "keeps each upload under its own key", %{listing: listing} do
      first = add_image!(listing, filename: "photo.png")
      second = add_image!(listing, filename: "photo.png")

      refute first.storage_key == second.storage_key
    end

    test "cannot be aimed out of the listing's own folder", %{listing: listing} do
      image = add_image!(listing, filename: "../../escape.png")

      refute image.storage_key =~ ".."
      assert {:ok, _bytes} = storage().get(image.storage_key)
    end

    test "requires the file itself", %{listing: listing} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.add_listing_image(%{listing_id: listing.id, filename: "photo.png"},
                 authorize?: false
               )
    end

    test "requires a listing" do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.add_listing_image(%{image: png_bytes(), filename: "orphan.png"},
                 authorize?: false
               )
    end

    test "stamps the created timestamp", %{listing: listing} do
      assert %DateTime{} = add_image!(listing).inserted_at
    end
  end

  describe "accepted files" do
    test "accepts each type the marketplace allows", %{listing: listing} do
      for {bytes, name} <- [
            {png_bytes(), "a.png"},
            {jpeg_bytes(), "a.jpg"},
            {webp_bytes(), "a.webp"}
          ] do
        assert {:ok, _image} = add_image(listing, image: bytes, filename: name)
      end
    end

    test "refuses a file that is not an image at all", %{listing: listing} do
      assert {:error, %Ash.Error.Invalid{}} =
               add_image(listing, image: "just some text", filename: "notes.png")
    end

    test "refuses an image type the marketplace does not allow", %{listing: listing} do
      # A GIF is recognisable, but not in the configured list.
      assert {:error, %Ash.Error.Invalid{}} =
               add_image(listing, image: <<"GIF89a", 0, 0>>, filename: "animation.gif")
    end

    test "judges the file by its bytes, not by the name it arrives under",
         %{listing: listing} do
      assert {:error, %Ash.Error.Invalid{}} =
               add_image(listing, image: "MZ not really an image", filename: "trojan.png")
    end

    test "accepts a file at the size limit", %{listing: listing} do
      assert {:ok, _image} = add_image(listing, image: png_of_size(max_bytes()))
    end

    test "refuses a file past the size limit", %{listing: listing} do
      assert {:error, %Ash.Error.Invalid{}} =
               add_image(listing, image: png_of_size(max_bytes() + 1))
    end

    test "stores nothing when the file is refused", %{listing: listing} do
      {:error, _} = add_image(listing, image: "just some text", filename: "notes.png")

      assert Listings.list_listing_images!(listing.id, authorize?: false) == []
    end
  end

  describe "stored files" do
    test "deleting an image deletes the file behind it", %{listing: listing} do
      image = add_image!(listing)
      assert {:ok, _bytes} = storage().get(image.storage_key)

      :ok = Listings.delete_listing_image(image, authorize?: false)

      assert {:error, _} = storage().get(image.storage_key)
    end

    test "deleting a listing deletes every file in its gallery", %{listing: listing} do
      images = for _ <- 1..3, do: add_image!(listing)

      :ok = Listings.delete_listing(listing, authorize?: false)

      for image <- images do
        assert {:error, _} = storage().get(image.storage_key)
      end
    end

    test "deleting a listing takes its image records with it", %{listing: listing} do
      add_image!(listing)

      :ok = Listings.delete_listing(listing, authorize?: false)

      assert Listings.list_listing_images!(listing.id, authorize?: false) == []
    end

    test "deleting a listing leaves another listing's files alone", %{listing: listing} do
      keeper = add_image!(generate(listing()))
      add_image!(listing)

      :ok = Listings.delete_listing(listing, authorize?: false)

      assert {:ok, _bytes} = storage().get(keeper.storage_key)
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

  defp add_image(listing, opts) do
    attrs = %{
      listing_id: listing.id,
      image: Keyword.get(opts, :image, png_bytes()),
      filename: Keyword.get(opts, :filename, "photo.png")
    }

    Listings.add_listing_image(attrs, authorize?: false)
  end

  defp add_image!(listing, opts \\ []) do
    {:ok, image} = add_image(listing, opts)

    image
  end

  defp storage, do: Application.fetch_env!(:mercato, :storage_adapter)

  defp max_bytes, do: Listings.image_max_bytes()

  defp jpeg_bytes, do: <<0xFF, 0xD8, 0xFF, 0xE0, "jfif">>

  defp webp_bytes, do: <<"RIFF", 0, 0, 0, 0, "WEBP", "vp8">>

  # A real PNG signature padded out to exactly `size` bytes.
  defp png_of_size(size) do
    signature = <<0x89, "PNG\r\n", 0x1A, 0x0A>>

    signature <> String.duplicate("x", size - byte_size(signature))
  end

  defp reload(image), do: Ash.reload!(image, authorize?: false)
end
