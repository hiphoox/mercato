defmodule Mercato.Listings.ListingGetMineTest do
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

  describe "get_my_listing" do
    test "returns the seller's own listing", %{seller: seller} do
      listing = generate(listing(actor: seller))

      assert {:ok, found} = Listings.get_my_listing(listing.id, actor: seller)
      assert found.id == listing.id
    end

    test "returns a draft, which no public read would show", %{seller: seller} do
      listing = generate(listing(actor: seller))

      assert {:ok, %{status: :draft}} = Listings.get_my_listing(listing.id, actor: seller)
    end

    test "returns a listing in every other state it can reach", %{seller: seller} do
      published = publish!(seller, generate(listing(actor: seller)))

      paused =
        Listings.pause_listing!(publish!(seller, generate(listing(actor: seller))), actor: seller)

      assert {:ok, %{status: :active}} = Listings.get_my_listing(published.id, actor: seller)
      assert {:ok, %{status: :unavailable}} = Listings.get_my_listing(paused.id, actor: seller)
    end

    test "refuses another seller's listing, published or not", %{seller: seller} do
      other = generate(user())
      draft = generate(listing(actor: other))
      live = publish!(other, generate(listing(actor: other)))

      assert {:error, %Ash.Error.Invalid{}} = Listings.get_my_listing(draft.id, actor: seller)
      assert {:error, %Ash.Error.Invalid{}} = Listings.get_my_listing(live.id, actor: seller)
    end

    test "refuses a caller acting as nobody", %{seller: seller} do
      listing = generate(listing(actor: seller))

      assert {:error, _} = Listings.get_my_listing(listing.id, actor: nil)
    end

    test "loads the gallery and the display price the form renders", %{seller: seller} do
      listing = generate(listing(actor: seller, price: 4200))
      generate(listing_image(listing: listing))

      assert {:ok, found} = Listings.get_my_listing(listing.id, actor: seller)
      assert [%{is_cover: true, url: url}] = found.images
      assert is_binary(url)
      assert found.display_price == "$42.00"
    end
  end
end
