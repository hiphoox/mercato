defmodule Mercato.Discovery.ParamsTest do
  use ExUnit.Case, async: true

  alias Mercato.Discovery

  @offered %{
    category: [{"bikes", "Bikes"}, {"furniture", "Furniture"}],
    price: [],
    condition: [{"good", "Good"}, {"fair", "Fair"}]
  }

  defp from_params(params), do: Discovery.from_params(params, @offered)

  describe "from_params/1" do
    test "reads a select facet stated in the address" do
      assert %{category: "bikes"} = from_params(%{"category" => "bikes"})
    end

    test "reads both ends of a range, in the units the grid compares against" do
      assert %{price: %{min: 1_000, max: 2_550}} =
               from_params(%{"price_min" => "10", "price_max" => "25.50"})
    end

    test "reads one end of a range and leaves the other open" do
      assert %{price: %{min: 1_000, max: nil}} = from_params(%{"price_min" => "10"})
    end

    test "leaves out a facet the address does not state" do
      assert from_params(%{}) == %{}
    end

    test "leaves out a facet stated as empty" do
      assert from_params(%{"category" => "", "condition" => "  "}) == %{}
    end

    test "leaves out a bound that cannot be read, so a hand-typed address still lands" do
      assert from_params(%{"price_min" => "cheap"}) == %{}
    end

    test "ignores a parameter no facet claims" do
      assert from_params(%{"mileage" => "120000"}) == %{}
    end

    test "ignores a value the facet does not offer, so a dropped category still browses" do
      assert from_params(%{"category" => "harpsichords"}) == %{}
    end

    test "ignores every value of a facet that offers none" do
      offered = %{category: [], price: [], condition: []}

      assert Discovery.from_params(%{"condition" => "good"}, offered) == %{}
    end
  end

  describe "to_params/1" do
    test "names a select facet by its key" do
      assert Discovery.to_params(%{category: "bikes"}) == [category: "bikes"]
    end

    test "writes a range back in the units a buyer typed it in" do
      assert Discovery.to_params(%{price: %{min: 1_000, max: 2_550}}) ==
               [price_min: "10.00", price_max: "25.50"]
    end

    test "leaves out an end of a range that is open" do
      assert Discovery.to_params(%{price: %{min: 1_000, max: nil}}) == [price_min: "10.00"]
    end

    test "leaves out a facet that is not in force" do
      assert Discovery.to_params(%{category: nil, condition: ""}) == []
    end

    test "orders the parameters the way the facets are declared" do
      params = Discovery.to_params(%{condition: "good", category: "bikes"})

      assert Keyword.keys(params) == [:category, :condition]
    end

    test "survives a round trip through the address" do
      filters = %{category: "bikes", price: %{min: 1_000, max: 2_550}, condition: "good"}

      round_tripped =
        filters
        |> Discovery.to_params()
        |> Map.new(fn {key, value} -> {to_string(key), value} end)
        |> from_params()

      assert round_tripped == filters
    end
  end

  describe "in_force?/2" do
    test "says a select facet with a value is narrowing the grid" do
      {:ok, facet} = Discovery.fetch(:category)

      assert Discovery.in_force?(facet, %{category: "bikes"})
    end

    test "says a facet left unstated is not" do
      {:ok, facet} = Discovery.fetch(:category)

      refute Discovery.in_force?(facet, %{})
    end

    test "says a range with either end stated is narrowing the grid" do
      {:ok, facet} = Discovery.fetch(:price)

      assert Discovery.in_force?(facet, %{price: %{min: 1_000, max: nil}})
      refute Discovery.in_force?(facet, %{price: %{min: nil, max: nil}})
    end
  end
end
