defmodule Mercato.Discovery.FacetTest do
  use ExUnit.Case, async: true

  alias Mercato.Discovery
  alias Mercato.Discovery.Facet

  describe "new/1" do
    test "builds a select facet from its declaration" do
      facet = Facet.new(key: :condition, kind: :select, field: :condition, label: "Condition")

      assert %Facet{key: :condition, kind: :select, field: :condition} = facet
    end

    test "draws on the bar unless the declaration says otherwise" do
      assert %Facet{placement: :bar} =
               Facet.new(key: :condition, kind: :select, field: :condition, label: "Condition")
    end

    test "takes a placement the declaration states" do
      assert %Facet{placement: :sheet} =
               Facet.new(
                 key: :condition,
                 kind: :select,
                 field: :condition,
                 label: "Condition",
                 placement: :sheet
               )
    end

    test "refuses a kind it cannot narrow by" do
      assert_raise ArgumentError, ~r/kind/, fn ->
        Facet.new(key: :colour, kind: :rainbow, field: :colour, label: "Colour")
      end
    end

    test "refuses a placement it cannot draw in" do
      assert_raise ArgumentError, ~r/placement/, fn ->
        Facet.new(key: :colour, kind: :select, field: :colour, label: "Colour", placement: :moon)
      end
    end

    test "refuses a declaration missing what it narrows" do
      assert_raise ArgumentError, ~r/field/, fn ->
        Facet.new(key: :colour, kind: :select, label: "Colour")
      end
    end

    test "reaches a field across a relationship when the declaration names a path" do
      assert %Facet{field: {[:category], :slug}} =
               Facet.new(
                 key: :category,
                 kind: :select,
                 field: {[:category], :slug},
                 label: "Category"
               )
    end
  end

  describe "params/1" do
    test "names a select facet by its own key" do
      facet = Facet.new(key: :condition, kind: :select, field: :condition, label: "Condition")

      assert Facet.params(facet) == ["condition"]
    end

    test "names both ends of a range facet, so one end can be stated alone" do
      facet = Facet.new(key: :price, kind: :range, field: :price, label: "Price")

      assert Facet.params(facet) == ["price_min", "price_max"]
    end
  end

  describe "facets/0" do
    test "offers category, price and condition out of the box" do
      assert Enum.map(Discovery.facets(), & &1.key) == [:category, :price, :condition]
    end

    test "offers what the marketplace configures instead" do
      declared = [[key: :brand, kind: :select, field: :brand, label: "Brand"]]

      Application.put_env(:mercato, :browse_facets, declared)
      on_exit(fn -> Application.delete_env(:mercato, :browse_facets) end)

      assert [%Facet{key: :brand}] = Discovery.facets()
    end

    test "offers none where the marketplace declares none" do
      Application.put_env(:mercato, :browse_facets, [])
      on_exit(fn -> Application.delete_env(:mercato, :browse_facets) end)

      assert Discovery.facets() == []
    end
  end

  describe "fetch/1" do
    test "finds a declared facet by its key" do
      assert {:ok, %Facet{key: :price}} = Discovery.fetch(:price)
    end

    test "finds nothing for a facet this marketplace does not offer" do
      assert Discovery.fetch(:mileage) == :error
    end
  end
end
