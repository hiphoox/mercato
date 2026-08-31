defmodule Mercato.Discovery.SortTest do
  use ExUnit.Case, async: false

  alias Mercato.Discovery
  alias Mercato.Discovery.Sort

  defp declare(sorts) do
    Application.put_env(:mercato, :browse_sorts, sorts)
    on_exit(fn -> Application.delete_env(:mercato, :browse_sorts) end)
  end

  describe "new/1" do
    test "builds a sort from its declaration" do
      assert %Sort{key: :price_asc, by: [price: :asc]} =
               Sort.new(key: :price_asc, label: "Price: low to high", by: [price: :asc])
    end

    test "orders by nothing of its own where the declaration says nothing" do
      assert %Sort{by: []} = Sort.new(key: :newest, label: "Newest")
    end

    test "refuses a declaration missing what it is called" do
      assert_raise ArgumentError, ~r/label/, fn -> Sort.new(key: :newest) end
    end

    test "refuses a declaration missing its key" do
      assert_raise ArgumentError, ~r/key/, fn -> Sort.new(label: "Newest") end
    end
  end

  describe "sorts/0" do
    test "offers newest and the two price orders out of the box" do
      assert Enum.map(Discovery.sorts(), & &1.key) == [:newest, :price_asc, :price_desc]
    end

    test "offers what the marketplace configures instead" do
      declare([[key: :mileage, label: "Fewest miles", by: [mileage: :asc]]])

      assert [%Sort{key: :mileage}] = Discovery.sorts()
    end
  end

  describe "default_sort/0" do
    test "is the first order declared" do
      assert %Sort{key: :newest} = Discovery.default_sort()
    end

    test "follows the declarations rather than a name it knows" do
      declare([
        [key: :price_asc, label: "Cheapest", by: [price: :asc]],
        [key: :newest, label: "Newest"]
      ])

      assert %Sort{key: :price_asc} = Discovery.default_sort()
    end
  end

  describe "fetch_sort/1" do
    test "finds a declared order by its key" do
      assert {:ok, %Sort{key: :price_desc}} = Discovery.fetch_sort(:price_desc)
    end

    test "finds nothing for an order this marketplace does not offer" do
      assert Discovery.fetch_sort(:cheapest_nearby) == :error
    end

    test "reads a key stated as a string, the way an address states it" do
      assert {:ok, %Sort{key: :price_asc}} = Discovery.fetch_sort("price_asc")
    end

    test "finds nothing for a string naming no order, without minting an atom" do
      assert Discovery.fetch_sort("cheapest_nearby_and_blue") == :error
    end
  end

  describe "order_by/1" do
    test "settles a tied row by the default order, so two reads agree" do
      {:ok, sort} = Discovery.fetch_sort(:price_asc)

      assert Discovery.order_by(sort) == [price: :asc, published_at: :desc, inserted_at: :desc]
    end

    test "leaves the default order as it was declared" do
      {:ok, sort} = Discovery.fetch_sort(:newest)

      assert Discovery.order_by(sort) == [published_at: :desc, inserted_at: :desc]
    end

    test "settles by whichever order the marketplace declared first" do
      declare([
        [key: :title, label: "A to Z", by: [title: :asc]],
        [key: :price_asc, label: "Cheapest", by: [price: :asc]]
      ])

      {:ok, sort} = Discovery.fetch_sort(:price_asc)

      assert Discovery.order_by(sort) == [price: :asc, title: :asc]
    end
  end
end
