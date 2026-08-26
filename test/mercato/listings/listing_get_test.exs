defmodule Mercato.Listings.ListingGetTest do
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

  describe "get_listing" do
    test "returns a listing on offer to a visitor acting as nobody", %{seller: seller} do
      live = publish!(seller, generate(listing(actor: seller)))

      assert {:ok, found} = Listings.get_listing(live.id, actor: nil)
      assert found.id == live.id
    end

    test "returns a listing on offer to a signed-in stranger", %{seller: seller} do
      live = publish!(seller, generate(listing(actor: seller)))

      assert {:ok, found} = Listings.get_listing(live.id, actor: generate(user()))
      assert found.id == live.id
    end

    test "hides a draft from everyone but its seller", %{seller: seller} do
      draft = generate(listing(actor: seller))

      assert {:error, %Ash.Error.Invalid{}} = Listings.get_listing(draft.id, actor: nil)
      assert {:ok, %{status: :draft}} = Listings.get_listing(draft.id, actor: seller)
    end

    test "hides a paused listing from everyone but its seller", %{seller: seller} do
      paused =
        Listings.pause_listing!(publish!(seller, generate(listing(actor: seller))), actor: seller)

      assert {:error, %Ash.Error.Invalid{}} = Listings.get_listing(paused.id, actor: nil)
      assert {:ok, %{status: :unavailable}} = Listings.get_listing(paused.id, actor: seller)
    end

    # Per docs/domain/listings/listings.md a listing that is not on offer is the
    # seller's alone, and being sold is not an exception to that.
    test "hides a sold listing from everyone but its seller", %{seller: seller} do
      sold =
        Listings.mark_listing_sold!(publish!(seller, generate(listing(actor: seller))),
          actor: nil
        )

      assert {:error, %Ash.Error.Invalid{}} = Listings.get_listing(sold.id, actor: nil)
      assert {:ok, %{status: :sold}} = Listings.get_listing(sold.id, actor: seller)
    end

    test "refuses an id that matches nothing", %{seller: _seller} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.get_listing(Ash.UUID.generate(), actor: nil)
    end

    test "loads everything the detail page renders", %{seller: seller} do
      category = generate(category(name: "Furniture"))

      live =
        publish!(
          seller,
          generate(listing(actor: seller, price: 4200, category_id: category.id))
        )

      assert {:ok, found} = Listings.get_listing(live.id, actor: nil)
      assert found.display_price == "$42.00"
      assert found.category.name == "Furniture"
      assert found.seller.id == seller.id
      assert [%{is_cover: true, url: url}] = found.images
      assert is_binary(url)
    end
  end

  describe "condition_label" do
    test "reads a stored condition the way a person writes it" do
      assert Listings.condition_label("like_new") == "Like new"
      assert Listings.condition_label("good") == "Good"
    end

    test "has nothing to say about a listing with no condition" do
      assert Listings.condition_label(nil) == nil
    end
  end
end
