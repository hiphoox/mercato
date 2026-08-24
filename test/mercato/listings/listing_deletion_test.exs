defmodule Mercato.Listings.ListingDeletionTest do
  use Mercato.DataCase, async: false

  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    seller = generate(user())

    moderator =
      generate(user()) |> grant_permission("listing:delete") |> grant_permission("admin:access")

    %{seller: seller, moderator: moderator, listing: generate(listing(actor: seller))}
  end

  describe "a seller deleting their own" do
    test "removes it outright", %{seller: seller, listing: listing} do
      assert :ok = Listings.delete_listing(listing, actor: seller)

      assert Listings.list_listings!(actor: seller) == []
    end

    test "takes the gallery and its files with it", %{seller: seller, listing: listing} do
      image = add_image(listing)
      assert {:ok, _bytes} = storage().get(image.storage_key)

      :ok = Listings.delete_listing(listing, actor: seller)

      assert {:error, _} = storage().get(image.storage_key)
    end

    test "refuses a listing that has been sold", %{seller: seller, listing: listing} do
      sold = listing |> publish(seller) |> sell()

      assert {:error, %Ash.Error.Invalid{}} = Listings.delete_listing(sold, actor: seller)
    end

    test "refuses when the caller's copy predates the sale", %{seller: seller, listing: listing} do
      active = publish(listing, seller)
      sell(active)

      # `active` still reads :active, but the row behind it has been sold.
      assert {:error, _} = Listings.delete_listing(active, actor: seller)
    end
  end

  describe "moderation deleting a listing" do
    test "keeps the record rather than destroying it", %{
      moderator: moderator,
      seller: seller,
      listing: listing
    } do
      listing = publish(listing, seller)

      assert :ok = Listings.moderate_delete_listing(listing, actor: moderator)

      assert [kept] = Listings.list_listings_for_moderation!(actor: moderator)
      assert kept.id == listing.id
      assert kept.status == :deleted
      assert %DateTime{} = kept.archived_at
    end

    test "takes it out of sight of everyone else", %{
      moderator: moderator,
      seller: seller,
      listing: listing
    } do
      listing = publish(listing, seller)
      stranger = generate(user())

      :ok = Listings.moderate_delete_listing(listing, actor: moderator)

      assert Listings.list_listings!(actor: seller) == []
      assert Listings.list_listings!(actor: stranger) == []
    end

    test "keeps the gallery as the backup it is", %{
      moderator: moderator,
      seller: seller,
      listing: listing
    } do
      image = add_image(listing)

      :ok = Listings.moderate_delete_listing(listing, actor: moderator)

      assert {:ok, _bytes} = storage().get(image.storage_key)
      assert [kept] = Listings.list_listing_images!(listing.id, authorize?: false)
      assert kept.id == image.id
    end

    test "may act on a sold listing, since the record survives", %{
      moderator: moderator,
      seller: seller,
      listing: listing
    } do
      sold = listing |> publish(seller) |> sell()

      assert :ok = Listings.moderate_delete_listing(sold, actor: moderator)
    end

    test "is refused to a seller acting on their own listing", %{
      seller: seller,
      listing: listing
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               Listings.moderate_delete_listing(listing, actor: seller)
    end

    test "is refused to anyone without the permission", %{listing: listing} do
      assert {:error, %Ash.Error.Forbidden{}} =
               Listings.moderate_delete_listing(listing, actor: generate(user()))
    end
  end

  describe "the moderation view" do
    test "is refused to someone outside the admin area", %{seller: seller} do
      assert {:error, %Ash.Error.Forbidden{}} =
               Listings.list_listings_for_moderation(actor: seller)
    end
  end

  # A listing needs something to show before it can go on offer.
  defp publish(listing, seller) do
    generate(listing_image(listing: listing))

    {:ok, listing} = Listings.publish_listing(listing, actor: seller)

    listing
  end

  defp sell(listing) do
    {:ok, listing} = Listings.mark_listing_sold(listing)

    listing
  end

  defp add_image(listing) do
    generate(listing_image(listing: listing))
  end

  defp storage, do: Application.fetch_env!(:mercato, :storage_adapter)
end
