defmodule Mercato.Listings.ListingSlugTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings.Listing.Slug

  @public_id "1f47693a-e1a6-4b06-ba29-28033858cf82"

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

      slug = Slug.slug(listing)

      # Cut at a word boundary, so the tail is the public id rather than half a
      # word plus the public id.
      assert Slug.public_id(slug) == listing.public_id

      title_part = String.replace_suffix(slug, "-" <> listing.public_id, "")
      assert Enum.all?(String.split(title_part, "-"), &(&1 == "word"))
      assert String.length(slug) <= 100
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
    test "reads the id through a title that itself ends in hyphenated words" do
      assert Slug.public_id("a-b-c-d-e-" <> @public_id) == @public_id
    end

    test "takes the last segment, whatever the title contributed" do
      assert Slug.public_id("vintage-leather-jacket-" <> @public_id) == @public_id
    end

    test "takes the whole param when the title contributed nothing" do
      assert Slug.public_id(@public_id) == @public_id
    end

    test "survives a title part that has since changed" do
      assert Slug.public_id("something-else-entirely-" <> @public_id) == @public_id
    end
  end
end
