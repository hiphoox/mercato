defmodule Mercato.Listings.ListingPublicIdTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  describe "public_id" do
    test "is stamped on every new listing" do
      assert %{public_id: public_id} = generate(listing())
      assert is_binary(public_id)
      assert public_id != ""
    end

    test "is short and free of characters a reader could mistake for another" do
      %{public_id: public_id} = generate(listing())

      assert String.length(public_id) == 8
      assert public_id =~ ~r/\A[0-9abcdefghjkmnpqrstvwxyz]+\z/
    end

    test "differs from one listing to the next" do
      ids = Enum.map(1..25, fn _ -> generate(listing()).public_id end)

      assert ids == Enum.uniq(ids)
    end

    test "survives an edit, so a link shared before it still resolves after", %{} do
      seller = generate(user())
      listing = generate(listing(actor: seller))

      edited = Listings.update_listing!(listing, %{title: "An entirely new title"}, actor: seller)

      assert edited.public_id == listing.public_id
    end

    test "is not something the caller may supply" do
      seller = generate(user())

      assert_raise Ash.Error.Invalid, ~r/public_id/, fn ->
        Listings.create_listing!(
          %{
            title: "Chosen title",
            price: 1000,
            category_id: generate(category()).id,
            public_id: "chosen00"
          },
          actor: seller
        )
      end
    end
  end

  describe "get_listing_by_public_id" do
    test "finds a listing on offer for a visitor acting as nobody" do
      seller = generate(user())
      draft = generate(listing(actor: seller))
      generate(listing_image(listing: draft))
      live = Listings.publish_listing!(draft, actor: seller)

      assert {:ok, found} = Listings.get_listing_by_public_id(live.public_id, actor: nil)
      assert found.id == live.id
    end

    test "hides a draft from everyone but its seller" do
      seller = generate(user())
      draft = generate(listing(actor: seller))

      assert {:error, %Ash.Error.Invalid{}} =
               Listings.get_listing_by_public_id(draft.public_id, actor: nil)

      assert {:ok, %{status: :draft}} =
               Listings.get_listing_by_public_id(draft.public_id, actor: seller)
    end

    test "loads everything the detail page renders" do
      seller = generate(user())
      draft = generate(listing(actor: seller))
      generate(listing_image(listing: draft))
      live = Listings.publish_listing!(draft, actor: seller)

      assert {:ok, found} = Listings.get_listing_by_public_id(live.public_id, actor: nil)
      assert %Mercato.Accounts.User{} = found.seller
      assert %Mercato.Listings.Category{} = found.category
      assert [%{url: url}] = found.images
      assert is_binary(url)
      assert is_binary(found.display_price)
    end
  end
end
