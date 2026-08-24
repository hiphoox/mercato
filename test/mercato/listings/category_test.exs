defmodule Mercato.Listings.CategoryTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  describe "create_category/2" do
    test "creates a category with a display name and a slug" do
      assert {:ok, category} =
               Listings.create_category(%{name: "Home & Garden", slug: "home-garden"},
                 authorize?: false
               )

      assert category.name == "Home & Garden"
      assert category.slug == "home-garden"
    end

    test "requires a name" do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_category(%{slug: "home-garden"}, authorize?: false)
    end

    test "requires a slug" do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_category(%{name: "Home & Garden"}, authorize?: false)
    end

    test "re-seeding the same slug renames rather than duplicating" do
      {:ok, first} =
        Listings.create_category(%{name: "Home", slug: "home-garden"}, authorize?: false)

      {:ok, second} =
        Listings.create_category(%{name: "Home & Garden", slug: "home-garden"}, authorize?: false)

      assert second.id == first.id
      assert second.name == "Home & Garden"
    end
  end

  describe "list_categories/1" do
    test "returns the seeded catalog" do
      category = generate(category())

      assert {:ok, categories} = Listings.list_categories(authorize?: false)
      assert category.id in Enum.map(categories, & &1.id)
    end
  end

  describe "listing relationship" do
    test "a category has many listings" do
      category = generate(category())
      seller = generate(user())

      listing = generate(listing(category_id: category.id, actor: seller))

      category = Ash.load!(category, :listings, authorize?: false)

      assert Enum.map(category.listings, & &1.id) == [listing.id]
    end
  end
end
