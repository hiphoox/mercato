defmodule Mercato.Listings.CategorySuggestTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  defp names(args), do: Enum.map(Listings.suggest_categories!(args), & &1.name)

  test "completes a term against a category's name" do
    generate(category(name: "Cameras & Photo", slug: "cameras-photo"))
    generate(category(name: "Vehicles", slug: "vehicles"))

    assert names(%{query: "camera"}) == ["Cameras & Photo"]
  end

  test "ignores case" do
    generate(category(name: "Cameras & Photo", slug: "cameras-photo"))

    assert names(%{query: "CAMERAS"}) == ["Cameras & Photo"]
  end

  test "matches the middle of a name, not only its start" do
    generate(category(name: "Home & Garden", slug: "home-garden"))

    assert names(%{query: "garden"}) == ["Home & Garden"]
  end

  test "offers nothing for a term nothing matches" do
    generate(category(name: "Vehicles", slug: "vehicles"))

    assert names(%{query: "harpsichord"}) == []
  end

  test "orders by name, so the same term always answers the same way" do
    generate(category(name: "Camping", slug: "camping"))
    generate(category(name: "Cameras", slug: "cameras"))

    assert names(%{query: "cam"}) == ["Cameras", "Camping"]
  end

  test "offers at most five" do
    for n <- 1..8, do: generate(category(name: "Camera gear #{n}", slug: "camera-gear-#{n}"))

    assert length(names(%{query: "camera"})) == 5
  end
end
