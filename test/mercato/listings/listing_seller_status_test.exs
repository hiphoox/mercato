defmodule Mercato.Listings.ListingSellerStatusTest do
  @moduledoc """
  A listing is only as public as the account behind it: a seller off the
  marketplace takes their listings with them, without any per-listing change.
  """

  use Mercato.DataCase, async: false

  import Mercato.TestGenerators

  alias Mercato.{Accounts, Listings}

  setup do
    seller = generate(user())

    %{seller: seller, listing: publish!(seller, generate(listing(actor: seller)))}
  end

  defp publish!(seller, listing) do
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp ban!(seller), do: Accounts.change_status!(seller, :banned, actor: admin_with_user_update())

  defp admin_with_user_update, do: generate(user()) |> grant_permission("user:update")

  describe "a banned seller's listing" do
    test "leaves the public catalog", %{seller: seller, listing: listing} do
      ban!(seller)

      assert Listings.list_listings!(actor: nil) == []
      assert {:error, %Ash.Error.Invalid{}} = Listings.get_listing(listing.id, actor: nil)

      assert {:error, %Ash.Error.Invalid{}} =
               Listings.get_listing_by_public_id(listing.public_id, actor: nil)

      assert Listings.list_seller_listings!(seller.id, actor: nil) == []
    end

    test "is hidden from a signed-in stranger too", %{seller: seller, listing: listing} do
      ban!(seller)
      stranger = generate(user())

      assert Listings.list_listings!(actor: stranger) == []
      assert {:error, %Ash.Error.Invalid{}} = Listings.get_listing(listing.id, actor: stranger)
    end

    # The listing is out of public view, not gone: a ban that is lifted has to
    # leave the seller their listings to put back on offer.
    test "is still the seller's own to see", %{seller: seller, listing: listing} do
      ban!(seller)

      assert [mine] = Listings.list_my_listings!(actor: seller)
      assert mine.id == listing.id
      assert {:ok, _} = Listings.get_my_listing(listing.id, actor: seller)
    end

    test "is still reachable by moderation", %{seller: seller, listing: listing} do
      ban!(seller)

      assert [seen] = Listings.list_listings_for_moderation!(actor: admin_user())
      assert seen.id == listing.id
    end
  end

  describe "a deleted seller's listing" do
    test "leaves the public catalog", %{seller: seller, listing: listing} do
      :ok = Accounts.delete_account(seller, actor: seller)

      assert Listings.list_listings!(actor: nil) == []
      assert {:error, %Ash.Error.Invalid{}} = Listings.get_listing(listing.id, actor: nil)
      assert Listings.list_seller_listings!(seller.id, actor: nil) == []
    end
  end

  describe "a restricted seller's listing" do
    # A restriction limits what the person may do inside the marketplace, not
    # whether strangers may still be shown what they have on offer.
    test "stays in the public catalog", %{seller: seller, listing: listing} do
      Accounts.change_status!(seller, :restricted, actor: admin_with_user_update())

      assert [found] = Listings.list_listings!(actor: nil)
      assert found.id == listing.id
      assert {:ok, _} = Listings.get_listing(listing.id, actor: nil)
      assert [_] = Listings.list_seller_listings!(seller.id, actor: nil)
    end
  end
end
