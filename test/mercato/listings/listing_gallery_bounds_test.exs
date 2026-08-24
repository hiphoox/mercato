defmodule Mercato.Listings.ListingGalleryBoundsTest do
  use Mercato.DataCase, async: false

  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    seller = generate(user())

    %{seller: seller, listing: generate(listing(actor: seller))}
  end

  describe "how many images a gallery takes" do
    test "fills up to the maximum the marketplace allows", %{listing: listing} do
      for _ <- 1..Listings.max_images(), do: add_image!(listing)

      assert length(Listings.list_listing_images!(listing.id, authorize?: false)) ==
               Listings.max_images()
    end

    test "refuses one past the maximum", %{listing: listing} do
      for _ <- 1..Listings.max_images(), do: add_image!(listing)

      assert {:error, %Ash.Error.Invalid{}} = add_image(listing)
    end
  end

  describe "how few a listing may go on offer with" do
    test "refuses to publish a listing with nothing to show", %{
      seller: seller,
      listing: listing
    } do
      assert {:error, %Ash.Error.Invalid{}} = Listings.publish_listing(listing, actor: seller)
    end

    test "publishes once the gallery meets the minimum", %{seller: seller, listing: listing} do
      for _ <- 1..Listings.min_images(), do: add_image!(listing)

      assert {:ok, listing} = Listings.publish_listing(listing, actor: seller)
      assert listing.status == :active
    end
  end

  describe "removing an image from a listing on offer" do
    test "refuses to take it below the minimum", %{seller: seller, listing: listing} do
      images = for _ <- 1..Listings.min_images(), do: add_image!(listing)
      {:ok, _} = Listings.publish_listing(listing, actor: seller)

      assert {:error, %Ash.Error.Invalid{}} =
               Listings.delete_listing_image(List.last(images), actor: seller)
    end

    test "allows it while the listing is still a draft", %{seller: seller, listing: listing} do
      image = add_image!(listing)

      assert :ok = Listings.delete_listing_image(image, actor: seller)
    end

    test "allows it while there is room to spare", %{seller: seller, listing: listing} do
      images = for _ <- 1..(Listings.min_images() + 1), do: add_image!(listing)
      {:ok, _} = Listings.publish_listing(listing, actor: seller)

      assert :ok = Listings.delete_listing_image(List.last(images), actor: seller)
    end
  end

  defp add_image(listing) do
    Listings.add_listing_image(
      %{listing_id: listing.id, image: png_bytes(), filename: "photo.png"},
      authorize?: false
    )
  end

  defp add_image!(listing) do
    {:ok, image} = add_image(listing)

    image
  end
end
