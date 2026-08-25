defmodule Mercato.Listings.ListingImageUrlTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  describe "url" do
    test "answers where the stored image can be fetched from" do
      image = generate(listing_image())

      [loaded] = Listings.list_listing_images!(image.listing_id, authorize?: false, load: [:url])

      adapter = Application.fetch_env!(:mercato, :storage_adapter)

      assert loaded.url == adapter.url(image.storage_key)
    end

    test "the gallery on a seller's own listing carries it", %{} do
      seller = generate(user())
      listing = generate(listing(actor: seller))
      generate(listing_image(listing: listing))

      assert [%{images: [image]}] = Listings.list_my_listings!(actor: seller)

      refute match?(%Ash.NotLoaded{}, image.url)
      assert image.url =~ image.storage_key
    end
  end
end
