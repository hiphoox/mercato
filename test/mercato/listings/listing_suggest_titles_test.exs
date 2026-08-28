defmodule Mercato.Listings.ListingSuggestTitlesTest do
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

  defp on_offer!(seller, opts) do
    publish!(seller, generate(listing(Keyword.put(opts, :actor, seller))))
  end

  defp titles(args, opts \\ []) do
    args |> Listings.suggest_listing_titles!(opts) |> Enum.map(& &1.title)
  end

  describe "matching" do
    test "completes a term against a title", %{seller: seller} do
      on_offer!(seller, title: "Eames-style lounge chair")
      on_offer!(seller, title: "Two-person tent")

      assert titles(%{query: "lounge"}) == ["Eames-style lounge chair"]
    end

    test "ignores the description, which is not what a completion offers", %{seller: seller} do
      on_offer!(seller, title: "Nondescript item", description: "Walnut shell, barely used")

      assert titles(%{query: "walnut"}) == []
    end

    test "ignores case in both the term and the stored title", %{seller: seller} do
      on_offer!(seller, title: "Steel-Frame ROAD Bike")

      assert titles(%{query: "road BIKE"}) == ["Steel-Frame ROAD Bike"]
    end

    test "matches a term containing an underscore", %{seller: seller} do
      on_offer!(seller, title: "Model x_200 turntable")
      on_offer!(seller, title: "Model x1200 turntable")

      assert titles(%{query: "x_200"}) == ["Model x_200 turntable"]
    end

    test "treats a percent sign as a character, not a wildcard", %{seller: seller} do
      on_offer!(seller, title: "Wool rug, 100% wool")
      on_offer!(seller, title: "Two-person tent")

      assert titles(%{query: "100%"}) == ["Wool rug, 100% wool"]
    end

    test "offers nothing for a term nothing matches", %{seller: seller} do
      on_offer!(seller, title: "Two-person tent")

      assert titles(%{query: "harpsichord"}) == []
    end
  end

  describe "shaping the list" do
    test "says a repeated title once, however many sellers list it", %{seller: seller} do
      other = generate(user())
      on_offer!(seller, title: "Folding chair")
      on_offer!(other, title: "Folding chair")

      assert titles(%{query: "folding"}) == ["Folding chair"]
    end

    test "treats titles differing only in case as one", %{seller: seller} do
      on_offer!(seller, title: "Folding Chair")
      on_offer!(seller, title: "folding chair")

      assert length(titles(%{query: "folding"})) == 1
    end

    test "offers at most five, since the panel is not a results page", %{seller: seller} do
      for n <- 1..8, do: on_offer!(seller, title: "Camera model #{n}")

      assert length(titles(%{query: "camera"})) == 5
    end
  end

  describe "scoping to a category" do
    setup do
      %{
        furniture: generate(category(slug: "furniture")),
        outdoor: generate(category(slug: "outdoor"))
      }
    end

    test "narrows to the named category", %{seller: seller, furniture: f, outdoor: o} do
      on_offer!(seller, title: "Folding chair", category_id: f.id)
      on_offer!(seller, title: "Folding stool", category_id: o.id)

      assert titles(%{query: "folding", category_slug: "furniture"}) == ["Folding chair"]
    end

    test "offers the whole catalog for a blank scope", %{seller: seller, furniture: f, outdoor: o} do
      on_offer!(seller, title: "Folding chair", category_id: f.id)
      on_offer!(seller, title: "Folding stool", category_id: o.id)

      assert length(titles(%{query: "folding", category_slug: ""})) == 2
    end
  end

  describe "what never completes" do
    test "a draft, which was never put in front of buyers", %{seller: seller} do
      generate(listing(actor: seller, title: "Draft lounge chair"))

      assert titles(%{query: "lounge"}) == []
    end

    test "a paused listing", %{seller: seller} do
      seller
      |> on_offer!(title: "Paused lounge chair")
      |> Listings.pause_listing!(actor: seller)

      assert titles(%{query: "lounge"}) == []
    end

    test "a sold listing", %{seller: seller} do
      seller
      |> on_offer!(title: "Sold lounge chair")
      |> Listings.mark_listing_sold!(actor: nil)

      assert titles(%{query: "lounge"}) == []
    end

    test "a listing whose seller is off the marketplace", %{seller: seller} do
      on_offer!(seller, title: "Banned seller's chair")
      admin = admin_user() |> grant_permission("user:update")
      Mercato.Accounts.change_status!(seller, :banned, actor: admin)

      assert titles(%{query: "chair"}) == []
    end

    # The panel previews the public shelf, so a seller is not completed against
    # their own drafts.
    test "the acting seller's own draft", %{seller: seller} do
      generate(listing(actor: seller, title: "My draft chair"))

      assert titles(%{query: "chair"}, actor: seller) == []
    end
  end
end
