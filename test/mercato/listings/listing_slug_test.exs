defmodule Mercato.Listings.ListingSlugTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings.Listing.Slug

  describe "slug/1" do
    test "reads as the title followed by the listing's public id" do
      listing = generate(listing(title: "Vintage Leather Jacket"))

      assert Slug.slug(listing) == "vintage-leather-jacket-#{listing.public_id}"
    end

    test "drops punctuation and collapses the gaps it leaves" do
      listing = generate(listing(title: "Nike Air Max 90 — like new!"))

      assert Slug.slug(listing) == "nike-air-max-90-like-new-#{listing.public_id}"
    end

    test "keeps a long title from running away with the URL" do
      listing = generate(listing(title: String.duplicate("word ", 28) |> String.trim()))

      [_ | _] = words = Slug.slug(listing) |> String.split("-")

      # Cut at a word boundary, so the tail is the public id rather than half a
      # word plus the public id.
      assert Enum.all?(words, &(&1 in ["word", listing.public_id]))
      assert String.length(Slug.slug(listing)) <= 80
    end

    test "reads an accented title as the letters underneath the accents" do
      listing = generate(listing(title: "Sillón Moderno, Hecho en México"))

      assert Slug.slug(listing) == "sillon-moderno-hecho-en-mexico-#{listing.public_id}"
    end

    test "falls back to the public id alone when the title leaves nothing behind" do
      listing = generate(listing(title: "日本語"))

      assert Slug.slug(listing) == listing.public_id
    end

    test "never ends in a separator, so the public id is always the last segment" do
      listing = generate(listing(title: "Trailing punctuation!!!"))

      assert Slug.public_id(Slug.slug(listing)) == listing.public_id
    end
  end

  describe "public_id/1" do
    test "takes the last segment, whatever the title contributed" do
      assert Slug.public_id("vintage-leather-jacket-7f3k9m2p") == "7f3k9m2p"
    end

    test "takes the whole param when the title contributed nothing" do
      assert Slug.public_id("7f3k9m2p") == "7f3k9m2p"
    end

    test "survives a title part that has since changed" do
      assert Slug.public_id("something-else-entirely-7f3k9m2p") == "7f3k9m2p"
    end
  end
end
