defmodule Mercato.Listings.ListingFacetOptionsTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  describe "condition_options/0" do
    test "words every condition the marketplace configures, in the order it lists them" do
      assert Listings.condition_options() == [
               {"new", "New"},
               {"like_new", "Like new"},
               {"good", "Good"},
               {"fair", "Fair"}
             ]
    end

    test "offers nothing where the marketplace configures no conditions" do
      Application.put_env(:mercato, :listing_conditions, [])
      on_exit(fn -> Application.delete_env(:mercato, :listing_conditions) end)

      assert Listings.condition_options() == []
    end
  end

  describe "category_options/0" do
    test "offers the catalog by slug, worded as the operator named it" do
      generate(category(name: "Furniture", slug: "furniture"))
      generate(category(name: "Bikes", slug: "bikes"))

      assert Listings.category_options() == [{"bikes", "Bikes"}, {"furniture", "Furniture"}]
    end

    test "offers nothing where the catalog is empty" do
      assert Listings.category_options() == []
    end
  end
end
