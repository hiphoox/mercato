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

  defp publish!(seller, %Listing{} = listing), do: publish!(listing, seller)

  defp publish!(%Listing{} = listing, seller) do
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
end
