defmodule Mercato.MoneyTest do
  use ExUnit.Case, async: true

  alias Mercato.Money

  describe "format/2" do
    test "reads minor units back as a major-unit amount" do
      assert Money.format(42_000, "USD") == "$420.00"
    end

    test "keeps the cents that a round amount would otherwise lose" do
      assert Money.format(1805, "USD") == "$18.05"
    end

    test "formats an amount below one major unit" do
      assert Money.format(7, "USD") == "$0.07"
    end

    test "uses the symbol of the currency it is given" do
      assert Money.format(1000, "EUR") == "€10.00"
      assert Money.format(1000, "GBP") == "£10.00"
    end

    test "falls back to the code for a currency it has no symbol for" do
      assert Money.format(1000, "SEK") == "SEK 10.00"
    end
  end
end
