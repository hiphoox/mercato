defmodule Mercato.Listings.ListingBrowseTest do
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

  defp on_offer!(seller, opts \\ []) do
    publish!(seller, generate(listing(Keyword.put(opts, :actor, seller))))
  end

  describe "browse_listings" do
    test "returns a listing on offer", %{seller: seller} do
      listing = on_offer!(seller)

      assert [found] = Listings.browse_listings!()
      assert found.id == listing.id
    end

    test "reads without an actor, since browsing is public", %{seller: seller} do
      on_offer!(seller)

      assert [_listing] = Listings.browse_listings!(actor: nil)
    end

    test "gathers every seller's listings, not one seller's", %{seller: seller} do
      other = generate(user())
      on_offer!(seller)
      on_offer!(other)

      assert length(Listings.browse_listings!()) == 2
    end

    test "puts the most recently published first", %{seller: seller} do
      first = on_offer!(seller)
      second = on_offer!(seller)
      third = on_offer!(seller)

      assert Enum.map(Listings.browse_listings!(), & &1.id) == [third.id, second.id, first.id]
    end

    test "leaves out a draft, which was never put in front of buyers", %{seller: seller} do
      generate(listing(actor: seller))

      assert Listings.browse_listings!() == []
    end

    test "leaves out a paused listing, which the seller took out of view", %{seller: seller} do
      seller |> on_offer!() |> Listings.pause_listing!(actor: seller)

      assert Listings.browse_listings!() == []
    end

    test "leaves out a sold listing, which is no longer on offer", %{seller: seller} do
      seller |> on_offer!() |> Listings.mark_listing_sold!(actor: nil)

      assert Listings.browse_listings!() == []
    end

    test "leaves out a listing whose seller is off the marketplace", %{seller: seller} do
      on_offer!(seller)
      admin = admin_user() |> grant_permission("user:update")
      Mercato.Accounts.change_status!(seller, :banned, actor: admin)

      assert Listings.browse_listings!() == []
    end

    test "hides the acting seller's own draft, unlike their own listings page", %{seller: seller} do
      generate(listing(actor: seller))

      assert Listings.browse_listings!(actor: seller) == []
    end

    test "loads what a card draws: the formatted price, the gallery and the seller", %{
      seller: seller
    } do
      on_offer!(seller)

      assert [listing] = Listings.browse_listings!()
      assert listing.display_price =~ "10.00"
      assert [%{url: url}] = listing.images
      assert is_binary(url)
      assert listing.seller.handle == seller.handle
    end
  end

  describe "browse_listings with a search term" do
    test "finds a listing by a word in its title", %{seller: seller} do
      on_offer!(seller, title: "Eames-style lounge chair")
      on_offer!(seller, title: "Two-person tent")

      assert [%{title: "Eames-style lounge chair"}] =
               Listings.browse_listings!(%{query: "lounge"})
    end

    test "finds a listing by a word in its description", %{seller: seller} do
      on_offer!(seller, title: "Nondescript item", description: "Walnut shell, barely used")
      on_offer!(seller, title: "Two-person tent")

      assert [%{title: "Nondescript item"}] = Listings.browse_listings!(%{query: "walnut"})
    end

    test "matches on the title alone when the description is blank", %{seller: seller} do
      on_offer!(seller, title: "Silk scarf", description: nil)

      assert [%{title: "Silk scarf"}] = Listings.browse_listings!(%{query: "scarf"})
    end

    # The term and the stored value differ only in case, which is the shape that
    # slips past a filter relying on SQLite's case-sensitive `instr`.
    test "ignores case in both the term and the stored value", %{seller: seller} do
      on_offer!(seller, title: "Steel-Frame ROAD Bike")

      assert [_found] = Listings.browse_listings!(%{query: "road BIKE"})
    end

    # An underscore is what `contains/2` breaks on here: it compiles to a LIKE
    # pattern escaped with a backslash and no ESCAPE clause, which SQLite
    # ignores, so the escape is matched literally and nothing comes back.
    test "matches a term containing an underscore", %{seller: seller} do
      on_offer!(seller, title: "Model x_200 turntable")
      on_offer!(seller, title: "Model x1200 turntable")

      assert [%{title: "Model x_200 turntable"}] = Listings.browse_listings!(%{query: "x_200"})
    end

    # `%` is a LIKE wildcard, so a term leaking into a pattern unescaped would
    # match every listing rather than the one that actually says so.
    test "treats a percent sign as a character, not a wildcard", %{seller: seller} do
      on_offer!(seller, title: "Wool rug, 100% wool")
      on_offer!(seller, title: "Two-person tent")

      assert [%{title: "Wool rug, 100% wool"}] = Listings.browse_listings!(%{query: "100%"})
    end

    test "returns nothing when no listing matches", %{seller: seller} do
      on_offer!(seller, title: "Two-person tent")

      assert Listings.browse_listings!(%{query: "harpsichord"}) == []
    end

    test "returns the whole shelf for a blank term", %{seller: seller} do
      on_offer!(seller)
      on_offer!(seller)

      assert length(Listings.browse_listings!(%{query: ""})) == 2
    end

    test "searches only what is on offer, never a draft", %{seller: seller} do
      generate(listing(actor: seller, title: "Draft lounge chair"))

      assert Listings.browse_listings!(%{query: "lounge"}) == []
    end

    test "keeps the newest first among the matches", %{seller: seller} do
      older = on_offer!(seller, title: "Older chair")
      newer = on_offer!(seller, title: "Newer chair")

      assert Enum.map(Listings.browse_listings!(%{query: "chair"}), & &1.id) ==
               [newer.id, older.id]
    end
  end

  describe "browse_listings scoped to a category" do
    setup do
      %{
        furniture: generate(category(slug: "furniture")),
        outdoor: generate(category(slug: "outdoor"))
      }
    end

    test "narrows the shelf to the named category", %{
      seller: seller,
      furniture: furniture,
      outdoor: outdoor
    } do
      chair = on_offer!(seller, category_id: furniture.id)
      on_offer!(seller, category_id: outdoor.id)

      assert [found] = Listings.browse_listings!(%{filters: %{category: "furniture"}})
      assert found.id == chair.id
    end

    test "returns the whole shelf for a blank slug", %{
      seller: seller,
      furniture: furniture,
      outdoor: outdoor
    } do
      on_offer!(seller, category_id: furniture.id)
      on_offer!(seller, category_id: outdoor.id)

      assert length(Listings.browse_listings!(%{filters: %{category: ""}})) == 2
    end

    test "defaults to the whole shelf when no slug is given", %{
      seller: seller,
      furniture: furniture,
      outdoor: outdoor
    } do
      on_offer!(seller, category_id: furniture.id)
      on_offer!(seller, category_id: outdoor.id)

      assert length(Listings.browse_listings!()) == 2
    end

    test "returns nothing for a slug no category holds", %{
      seller: seller,
      furniture: furniture
    } do
      on_offer!(seller, category_id: furniture.id)

      assert Listings.browse_listings!(%{filters: %{category: "harpsichords"}}) == []
    end

    test "narrows by the term and the scope together", %{
      seller: seller,
      furniture: furniture,
      outdoor: outdoor
    } do
      chair = on_offer!(seller, title: "Folding chair", category_id: furniture.id)
      on_offer!(seller, title: "Folding chair", category_id: outdoor.id)
      on_offer!(seller, title: "Two-person tent", category_id: furniture.id)

      assert [found] =
               Listings.browse_listings!(%{query: "chair", filters: %{category: "furniture"}})

      assert found.id == chair.id
    end

    test "still leaves out a draft in the scoped category", %{
      seller: seller,
      furniture: furniture
    } do
      generate(listing(actor: seller, category_id: furniture.id))

      assert Listings.browse_listings!(%{filters: %{category: "furniture"}}) == []
    end
  end

  describe "browse_listings ordered by price" do
    setup %{seller: seller} do
      %{
        dear: on_offer!(seller, title: "Turntable", price: 68_000),
        cheap: on_offer!(seller, title: "Paperbacks", price: 3_200),
        middling: on_offer!(seller, title: "Kilim runner", price: 15_500)
      }
    end

    test "puts the cheapest first when asked", ctx do
      ids = Listings.browse_listings!(%{sort: :price_asc}) |> Enum.map(& &1.id)

      assert ids == [ctx.cheap.id, ctx.middling.id, ctx.dear.id]
    end

    test "puts the dearest first when asked", ctx do
      ids = Listings.browse_listings!(%{sort: :price_desc}) |> Enum.map(& &1.id)

      assert ids == [ctx.dear.id, ctx.middling.id, ctx.cheap.id]
    end

    test "still leads with the newest when asked for that", ctx do
      ids = Listings.browse_listings!(%{sort: :newest}) |> Enum.map(& &1.id)

      assert ids == [ctx.middling.id, ctx.cheap.id, ctx.dear.id]
    end

    test "leads with the newest when asked for nothing, so a plain read is unchanged", ctx do
      ids = Listings.browse_listings!() |> Enum.map(& &1.id)

      assert ids == [ctx.middling.id, ctx.cheap.id, ctx.dear.id]
    end

    test "breaks a tie on price by recency, so equal prices do not shuffle", %{seller: seller} do
      first = on_offer!(seller, price: 500)
      second = on_offer!(seller, price: 500)

      ids = Listings.browse_listings!(%{sort: :price_asc}) |> Enum.map(& &1.id)

      assert Enum.take(ids, 2) == [second.id, first.id]
    end

    test "narrows and orders together", %{seller: seller} do
      cheap = on_offer!(seller, title: "Cheap chair", price: 1_000)
      dear = on_offer!(seller, title: "Dear chair", price: 90_000)

      ids =
        Listings.browse_listings!(%{query: "chair", sort: :price_asc}) |> Enum.map(& &1.id)

      assert ids == [cheap.id, dear.id]
    end

    test "refuses an ordering it does not offer" do
      assert {:error, _} = Listings.browse_listings(%{sort: :cheapest_nearby})
    end
  end

  describe "browse_listings narrowed by price" do
    setup %{seller: seller} do
      %{
        cheap: on_offer!(seller, price: 1_000),
        middling: on_offer!(seller, price: 5_000),
        dear: on_offer!(seller, price: 20_000)
      }
    end

    test "leaves out what costs less than the floor asked for", ctx do
      ids = Listings.browse_listings!(%{filters: %{price: %{min: 5_000}}}) |> Enum.map(& &1.id)

      assert Enum.sort(ids) == Enum.sort([ctx.middling.id, ctx.dear.id])
    end

    test "leaves out what costs more than the ceiling asked for", ctx do
      ids = Listings.browse_listings!(%{filters: %{price: %{max: 5_000}}}) |> Enum.map(& &1.id)

      assert Enum.sort(ids) == Enum.sort([ctx.cheap.id, ctx.middling.id])
    end

    test "keeps a listing priced exactly at either bound, since a range includes its ends", ctx do
      ids =
        Listings.browse_listings!(%{filters: %{price: %{min: 5_000, max: 5_000}}})
        |> Enum.map(& &1.id)

      assert ids == [ctx.middling.id]
    end

    test "reads an unset bound as no bound at all", ctx do
      ids =
        Listings.browse_listings!(%{filters: %{price: %{min: nil, max: nil}}})
        |> Enum.map(& &1.id)

      assert Enum.sort(ids) ==
               Enum.sort([ctx.cheap.id, ctx.middling.id, ctx.dear.id])
    end

    test "returns nothing when the range excludes everything on offer" do
      assert Listings.browse_listings!(%{filters: %{price: %{min: 100_000}}}) == []
    end

    test "narrows by term and by price together", %{seller: seller} do
      chair = on_offer!(seller, title: "Oak chair", price: 4_000)
      on_offer!(seller, title: "Oak chair", price: 40_000)

      ids =
        Listings.browse_listings!(%{query: "chair", filters: %{price: %{max: 10_000}}})
        |> Enum.map(& &1.id)

      assert ids == [chair.id]
    end
  end

  describe "browse_listings narrowed by condition" do
    setup %{seller: seller} do
      %{
        pristine: on_offer!(seller, condition: "new"),
        worn: on_offer!(seller, condition: "fair"),
        unstated: on_offer!(seller, condition: nil)
      }
    end

    test "returns only what is in the condition asked for", ctx do
      ids = Listings.browse_listings!(%{filters: %{condition: "new"}}) |> Enum.map(& &1.id)

      assert ids == [ctx.pristine.id]
    end

    test "leaves out a listing whose seller stated no condition", ctx do
      ids = Listings.browse_listings!(%{filters: %{condition: "fair"}}) |> Enum.map(& &1.id)

      assert ids == [ctx.worn.id]
    end

    test "reads an unstated condition as no narrowing, not as a listing with none", ctx do
      ids = Listings.browse_listings!(%{filters: %{condition: ""}}) |> Enum.map(& &1.id)

      assert Enum.sort(ids) ==
               Enum.sort([ctx.pristine.id, ctx.worn.id, ctx.unstated.id])
    end

    test "returns nothing for a condition nothing on offer is in" do
      assert Listings.browse_listings!(%{filters: %{condition: "like_new"}}) == []
    end
  end
end
