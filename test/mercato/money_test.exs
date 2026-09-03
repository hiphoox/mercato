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

  describe "to_minor/1" do
    test "reads a typed amount as the minor units a listing stores" do
      assert Money.to_minor("420.50") == {:ok, 42_050}
    end

    test "reads a whole amount as having no cents" do
      assert Money.to_minor("420") == {:ok, 42_000}
    end

    test "pads a single decimal place out to cents" do
      assert Money.to_minor("420.5") == {:ok, 42_050}
    end

    test "reads an amount below one major unit" do
      assert Money.to_minor("0.07") == {:ok, 7}
    end

    test "ignores the spaces a person leaves around what they typed" do
      assert Money.to_minor("  18.05  ") == {:ok, 1805}
    end

    test "refuses more precision than the currency has, rather than rounding it away" do
      assert Money.to_minor("420.567") == :error
    end

    test "refuses an amount that is not a number" do
      assert Money.to_minor("abc") == :error
      assert Money.to_minor("12abc") == :error
      assert Money.to_minor("") == :error
    end

    test "refuses a negative amount, which no listing may hold" do
      assert Money.to_minor("-5.00") == :error
    end
  end

  describe "percent/1" do
    test "reads basis points back as a percentage a person writes" do
      assert Money.percent(250) == "2.5%"
    end

    test "drops the decimals a whole percentage does not need" do
      assert Money.percent(1000) == "10%"
    end

    test "keeps the fraction of a percent a small rate is made of" do
      assert Money.percent(5) == "0.05%"
    end

    test "reads nothing back for a rate that has not been set" do
      assert Money.percent(nil) == nil
    end
  end

  describe "rate/1" do
    test "reads basis points back with no percent sign on the end" do
      assert Money.rate(250) == "2.5"
      assert Money.rate(1000) == "10"
      assert Money.rate(nil) == nil
    end
  end

  describe "to_basis_points/1" do
    test "reads a typed percentage as the basis points a rate stores" do
      assert Money.to_basis_points("2.5") == {:ok, 250}
      assert Money.to_basis_points("10") == {:ok, 1000}
      assert Money.to_basis_points("0.05") == {:ok, 5}
    end

    test "ignores the spaces a person leaves around what they typed" do
      assert Money.to_basis_points("  2.5  ") == {:ok, 250}
    end

    test "refuses more precision than a basis point holds, rather than rounding it away" do
      assert Money.to_basis_points("2.555") == :error
    end

    test "refuses a rate that is not a number" do
      assert Money.to_basis_points("abc") == :error
      assert Money.to_basis_points("") == :error
      assert Money.to_basis_points("-2.5") == :error
    end
  end

  describe "apply_rate/2" do
    test "takes a rate of an amount" do
      assert Money.apply_rate(10_000, 250) == 250
    end

    test "rounds a half minor unit up rather than losing it" do
      assert Money.apply_rate(1010, 250) == 25
      assert Money.apply_rate(1030, 250) == 26
    end

    test "takes nothing at all for a rate of nothing" do
      assert Money.apply_rate(10_000, 0) == 0
    end

    test "takes the whole amount for a rate of everything" do
      assert Money.apply_rate(10_000, 10_000) == 10_000
    end
  end
end
