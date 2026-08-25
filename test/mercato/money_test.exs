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

  describe "amount/1" do
    test "reads minor units back without a currency on the front" do
      assert Money.amount(42_000) == "420.00"
    end

    test "keeps the cents a round amount would otherwise lose" do
      assert Money.amount(1805) == "18.05"
      assert Money.amount(7) == "0.07"
    end

    test "reads nothing back for an amount that has not been set" do
      assert Money.amount(nil) == nil
    end
  end

  describe "symbol/1" do
    test "gives the symbol of a currency it knows" do
      assert Money.symbol("USD") == "$"
      assert Money.symbol("EUR") == "€"
    end

    test "falls back to the code for a currency it has no symbol for" do
      assert Money.symbol("SEK") == "SEK"
    end
  end
end
