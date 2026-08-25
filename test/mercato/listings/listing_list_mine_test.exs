defmodule Mercato.Listings.ListingListMineTest do
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

  describe "list_my_listings" do
    test "returns the seller's own listings", %{seller: seller} do
      listing = generate(listing(actor: seller))

      assert [found] = Listings.list_my_listings!(actor: seller)
      assert found.id == listing.id
    end

    test "returns a draft, which no public read would show", %{seller: seller} do
      generate(listing(actor: seller))

      assert [%{status: :draft}] = Listings.list_my_listings!(actor: seller)
    end

    test "returns a paused listing, which no public read would show", %{seller: seller} do
      listing = seller |> publish!(generate(listing(actor: seller)))
      Listings.pause_listing!(listing, actor: seller)

      assert [%{status: :unavailable}] = Listings.list_my_listings!(actor: seller)
    end

    test "leaves out another seller's listing, even one on offer", %{seller: seller} do
      other = generate(user())
      publish!(other, generate(listing(actor: other)))

      assert Listings.list_my_listings!(actor: seller) == []
    end

    test "refuses a caller acting as nobody, since \"mine\" needs someone to be" do
      seller = generate(user())
      generate(listing(actor: seller))

      assert_raise Ash.Error.Invalid, fn -> Listings.list_my_listings!(actor: nil) end
    end

    test "hands back the gallery, so a card can show its cover", %{seller: seller} do
      listing = generate(listing(actor: seller))
      image = generate(listing_image(listing: listing))

      assert [%{images: [found]}] = Listings.list_my_listings!(actor: seller)
      assert found.id == image.id
    end

    test "puts the most recently touched listing first", %{seller: seller} do
      older = generate(listing(actor: seller))
      newer = generate(listing(actor: seller))

      # Touched after `newer` was created, so recency has to come from the
      # update rather than from creation order.
      Listings.update_listing!(older, %{title: "Touched last"}, actor: seller)

      assert [%{id: first}, %{id: second}] = Listings.list_my_listings!(actor: seller)
      assert first == older.id
      assert second == newer.id
    end
  end
end
