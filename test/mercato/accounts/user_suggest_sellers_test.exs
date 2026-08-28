defmodule Mercato.Accounts.UserSuggestSellersTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Accounts
  alias Mercato.Listings

  defp publish!(seller, listing) do
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp selling!(opts) do
    {listing_opts, user_opts} = Keyword.split(opts, [:category_id])
    seller = generate(user(user_opts))

    publish!(seller, generate(listing(Keyword.put(listing_opts, :actor, seller))))

    seller
  end

  defp handles(args), do: Enum.map(Accounts.suggest_sellers!(args), & &1.handle)

  describe "matching" do
    test "completes a term against a first name" do
      seller = selling!(first_name: "Anaximander", last_name: "Ruiz")

      assert handles(%{query: "anaxim"}) == [seller.handle]
    end

    test "completes a term against a last name" do
      seller = selling!(first_name: "Jo", last_name: "Krzyzewski")

      assert handles(%{query: "krzyz"}) == [seller.handle]
    end

    test "completes a term against the handle itself" do
      seller = selling!(first_name: "Jo", last_name: "Vance")

      assert handles(%{query: seller.handle}) == [seller.handle]
    end

    test "ignores case" do
      seller = selling!(first_name: "Anaximander", last_name: "Ruiz")

      assert handles(%{query: "ANAXIM"}) == [seller.handle]
    end

    # The admin listing this read resembles matches email too, because it is
    # admin-only. This one is anonymous, so an address is not a way in.
    test "never matches an email address" do
      selling!(first_name: "Jo", last_name: "Vance", email: "findme@mercato.app")

      assert handles(%{query: "findme"}) == []
    end

    test "offers nothing for a term nothing matches" do
      selling!(first_name: "Jo", last_name: "Vance")

      assert handles(%{query: "harpsichord"}) == []
    end

    test "offers at most three" do
      for n <- 1..5, do: selling!(first_name: "Anaximander", last_name: "Number#{n}")

      assert length(handles(%{query: "anaxim"})) == 3
    end
  end

  describe "who is offered" do
    test "leaves out an account with nothing on offer" do
      generate(user(first_name: "Anaximander", last_name: "Ruiz"))

      assert handles(%{query: "anaxim"}) == []
    end

    test "leaves out an account whose only listing is a draft" do
      seller = generate(user(first_name: "Anaximander", last_name: "Ruiz"))
      generate(listing(actor: seller))

      assert handles(%{query: "anaxim"}) == []
    end

    # The exists reads the listings table directly, so nothing a Listing read
    # would filter applies here — it is the moderated status that excludes it.
    test "leaves out an account whose only listing moderation took down" do
      seller = selling!(first_name: "Anaximander", last_name: "Ruiz")
      admin = admin_user() |> grant_permission("listing:delete")
      [listing] = Listings.list_seller_listings!(seller.id)
      Listings.moderate_delete_listing!(listing, actor: admin)

      assert handles(%{query: "anaxim"}) == []
    end

    test "leaves out an account off the marketplace" do
      seller = selling!(first_name: "Anaximander", last_name: "Ruiz")
      admin = admin_user() |> grant_permission("user:update")
      Accounts.change_status!(seller, :banned, actor: admin)

      assert handles(%{query: "anaxim"}) == []
    end
  end

  describe "scoping to a category" do
    test "keeps only sellers with something on offer in that category" do
      furniture = generate(category(slug: "furniture"))
      outdoor = generate(category(slug: "outdoor"))

      inside = selling!(first_name: "Anaximander", last_name: "Ruiz", category_id: furniture.id)
      selling!(first_name: "Anaximander", last_name: "Vance", category_id: outdoor.id)

      assert handles(%{query: "anaxim", category_slug: "furniture"}) == [inside.handle]
    end

    test "offers every seller for a blank scope" do
      furniture = generate(category(slug: "furniture"))
      outdoor = generate(category(slug: "outdoor"))

      selling!(first_name: "Anaximander", last_name: "Ruiz", category_id: furniture.id)
      selling!(first_name: "Anaximander", last_name: "Vance", category_id: outdoor.id)

      assert length(handles(%{query: "anaxim", category_slug: ""})) == 2
    end
  end
end
