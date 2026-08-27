defmodule Mercato.Listings.ListingLifecycleTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings
  alias Mercato.Listings.Listing

  setup do
    seller = generate(user())

    %{seller: seller, listing: generate(listing(actor: seller))}
  end

  describe "states" do
    test "covers composing, offering, pausing, selling and withdrawing" do
      assert Listing.Status.values() == [:draft, :active, :unavailable, :sold, :deleted]
    end

    test "a new listing is the seller's draft", %{listing: listing} do
      assert listing.status == :draft
      assert listing.published_at == nil
    end
  end

  describe "publish" do
    test "offers the draft to buyers", %{seller: seller, listing: listing} do
      generate(listing_image(listing: listing))

      assert {:ok, listing} = Listings.publish_listing(listing, actor: seller)

      assert listing.status == :active
    end

    test "records when it was first published", %{seller: seller, listing: listing} do
      assert %DateTime{} = publish!(seller, listing).published_at
    end

    test "does not republish for a caller holding an older copy",
         %{seller: seller, listing: listing} do
      first = publish!(seller, listing)

      # `listing` still reads :draft, though it has already been published.
      assert {:error, _} = Listings.publish_listing(listing, actor: seller)
      assert Ash.reload!(first, actor: seller).published_at == first.published_at
    end

    test "refuses a listing already being offered", %{seller: seller, listing: listing} do
      listing = publish!(seller, listing)

      assert {:error, %Ash.Error.Invalid{}} = Listings.publish_listing(listing, actor: seller)
    end
  end

  describe "pause and resume" do
    test "pausing takes it off offer without losing it", %{seller: seller, listing: listing} do
      listing = listing |> publish!(seller) |> pause!(seller)

      assert listing.status == :unavailable
    end

    test "resuming puts it back on offer", %{seller: seller, listing: listing} do
      listing = listing |> publish!(seller) |> pause!(seller)

      assert {:ok, listing} = Listings.resume_listing(listing, actor: seller)
      assert listing.status == :active
    end

    test "the first publication date survives a pause", %{seller: seller, listing: listing} do
      published = publish!(seller, listing)
      resumed = published |> pause!(seller) |> resume!(seller)

      assert resumed.published_at == published.published_at
    end

    test "refuses pausing a listing never offered", %{seller: seller, listing: listing} do
      assert {:error, %Ash.Error.Invalid{}} = Listings.pause_listing(listing, actor: seller)
    end

    test "refuses resuming a listing stripped of the photos it needs", %{
      seller: seller,
      listing: listing
    } do
      paused = listing |> publish!(seller) |> pause!(seller)

      # Nothing stops this while paused: the minimum guards a listing on offer,
      # and a paused one is not.
      for image <- Listings.list_listing_images!(paused.id, authorize?: false) do
        :ok = Listings.delete_listing_image(image, actor: seller)
      end

      assert {:error, %Ash.Error.Invalid{}} = Listings.resume_listing(paused, actor: seller)
      assert {:ok, %{status: :unavailable}} = Listings.get_my_listing(paused.id, actor: seller)
    end

    test "refuses resuming a listing already on offer", %{seller: seller, listing: listing} do
      listing = publish!(seller, listing)

      assert {:error, %Ash.Error.Invalid{}} = Listings.resume_listing(listing, actor: seller)
    end
  end

  describe "sold" do
    test "a completed purchase takes it off offer", %{seller: seller, listing: listing} do
      listing = publish!(seller, listing)

      assert {:ok, listing} = Listings.mark_listing_sold(listing)
      assert listing.status == :sold
    end

    test "is not something the seller does by hand", %{seller: seller, listing: listing} do
      listing = publish!(seller, listing)

      assert {:error, %Ash.Error.Forbidden{}} =
               Listings.mark_listing_sold(listing, actor: seller)
    end

    test "cannot be reached from a draft", %{seller: seller, listing: listing} do
      assert {:error, %Ash.Error.Invalid{}} = Listings.mark_listing_sold(listing)
      assert publish!(seller, listing).status == :active
    end

    test "stays sold even for a caller holding an older copy",
         %{seller: seller, listing: listing} do
      active = publish!(seller, listing)
      sold!(active)

      # `active` still reads :active, but the row behind it has been sold.
      assert {:error, _} = Listings.pause_listing(active, actor: seller)
      assert Ash.reload!(active, actor: seller).status == :sold
    end

    test "is the end of the line", %{seller: seller, listing: listing} do
      sold = listing |> publish!(seller) |> sold!()

      assert {:error, %Ash.Error.Invalid{}} = Listings.publish_listing(sold, actor: seller)
      assert {:error, %Ash.Error.Invalid{}} = Listings.pause_listing(sold, actor: seller)
      assert {:error, %Ash.Error.Invalid{}} = Listings.resume_listing(sold, actor: seller)
      assert {:error, %Ash.Error.Invalid{}} = Listings.mark_listing_sold(sold)
    end
  end

  describe "who can see what" do
    test "a stranger sees only what is on offer", %{seller: seller, listing: draft} do
      stranger = generate(user())
      offered = seller |> new_listing() |> publish!(seller)
      paused = seller |> new_listing() |> publish!(seller) |> pause!(seller)

      visible = ids_visible_to(stranger)

      assert offered.id in visible
      refute draft.id in visible
      refute paused.id in visible
    end

    test "a seller sees their own whatever state it is in", %{seller: seller, listing: draft} do
      paused = seller |> new_listing() |> publish!(seller) |> pause!(seller)

      visible = ids_visible_to(seller)

      assert draft.id in visible
      assert paused.id in visible
    end

    test "a seller does not see another seller's draft", %{listing: draft} do
      other = generate(user())

      refute draft.id in ids_visible_to(other)
    end
  end

  describe "who can act" do
    test "a signed-in user may list something", %{seller: seller} do
      category = generate(category())

      assert {:ok, listing} =
               Listings.create_listing(%{title: "Mine", price: 100, category_id: category.id},
                 actor: seller
               )

      assert listing.seller_id == seller.id
    end

    test "a listing cannot be created with nobody to own it" do
      category = generate(category())

      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_listing(%{title: "Nobody's", price: 100, category_id: category.id})
    end

    # On offer, so the listing is plainly visible to the other seller and it is
    # ownership deciding the answer rather than the listing being out of sight.
    test "only the seller may edit", %{seller: seller, listing: listing} do
      listing = publish!(seller, listing)
      other = generate(user())

      assert {:error, %Ash.Error.Forbidden{}} =
               Listings.update_listing(listing, %{title: "Hijacked"}, actor: other)
    end

    test "only the seller may pause", %{seller: seller, listing: listing} do
      listing = publish!(seller, listing)
      other = generate(user())

      assert {:error, %Ash.Error.Forbidden{}} = Listings.pause_listing(listing, actor: other)
    end

    test "only the seller may resume", %{seller: seller, listing: listing} do
      paused = listing |> publish!(seller) |> Listings.pause_listing!(actor: seller)
      other = generate(user())

      assert {:error, %Ash.Error.Forbidden{}} = Listings.resume_listing(paused, actor: other)
    end

    test "only the seller may delete", %{seller: seller, listing: listing} do
      listing = publish!(seller, listing)
      other = generate(user())

      assert {:error, %Ash.Error.Forbidden{}} = Listings.delete_listing(listing, actor: other)
    end

    test "only the seller may publish", %{listing: listing} do
      other = generate(user())

      # Ready to go on offer, so it is ownership being refused rather than the
      # listing having nothing to show.
      generate(listing_image(listing: listing))

      assert {:error, %Ash.Error.Forbidden{}} = Listings.publish_listing(listing, actor: other)
    end

    test "the seller may delete their own", %{seller: seller, listing: listing} do
      assert :ok = Listings.delete_listing(listing, actor: seller)
    end
  end

  defp new_listing(seller), do: generate(listing(actor: seller))

  defp publish!(seller, %Listing{} = listing), do: publish!(listing, seller)

  # A listing needs something to show before it can go on offer, and every test
  # here is about the state it moves to rather than about the gallery.
  defp publish!(%Listing{} = listing, seller) do
    generate(listing_image(listing: listing))

    {:ok, listing} = Listings.publish_listing(listing, actor: seller)

    listing
  end

  defp pause!(listing, seller) do
    {:ok, listing} = Listings.pause_listing(listing, actor: seller)

    listing
  end

  defp resume!(listing, seller) do
    {:ok, listing} = Listings.resume_listing(listing, actor: seller)

    listing
  end

  defp sold!(listing) do
    {:ok, listing} = Listings.mark_listing_sold(listing)

    listing
  end

  defp ids_visible_to(actor) do
    Listings.list_listings!(actor: actor) |> Enum.map(& &1.id)
  end
end
