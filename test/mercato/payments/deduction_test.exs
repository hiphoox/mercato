defmodule Mercato.Payments.DeductionTest do
  use ExUnit.Case, async: true

  alias Mercato.Payments.Deduction

  defp flat(name, amount), do: Deduction.new!(name: name, kind: :flat, amount: amount)

  defp percentage(name, rate_bp, of \\ nil) do
    Deduction.new!(name: name, kind: :percentage, rate_bp: rate_bp, of: of)
  end

  describe "breakdown/2" do
    test "leaves the whole sale price where nothing is deducted" do
      assert Deduction.breakdown([], 10_000) == %{lines: [], total: 0, net: 10_000}
    end

    test "takes a flat row whatever the sale came to" do
      rows = [flat("Listing fee", 99)]

      assert %{lines: [%{name: "Listing fee", amount: 99}], total: 99, net: 9901} =
               Deduction.breakdown(rows, 10_000)

      assert %{total: 99, net: 401} = Deduction.breakdown(rows, 500)
    end

    test "takes a percentage row off the sale price" do
      rows = [percentage("Commission", 1000)]

      assert %{lines: [%{name: "Commission", amount: 1000}], total: 1000, net: 9000} =
               Deduction.breakdown(rows, 10_000)
    end

    test "stacks a jurisdiction's tax on the commission it is charged on" do
      rows = [percentage("Commission", 1000), percentage("VAT", 2100, "Commission")]

      assert %{
               lines: [
                 %{name: "Commission", amount: 1000},
                 %{name: "VAT", amount: 210}
               ],
               total: 1210,
               net: 8790
             } = Deduction.breakdown(rows, 10_000)
    end

    test "reads a row that is a percentage of one listed after it" do
      rows = [percentage("Surcharge", 5000, "VAT"), percentage("VAT", 2100)]

      assert %{total: 3150} = Deduction.breakdown(rows, 10_000)
    end

    test "rounds a half minor unit up rather than losing it" do
      assert %{total: 26} = Deduction.breakdown([percentage("Commission", 250)], 1030)
    end

    test "lists the rows in the order they are given" do
      rows = [flat("Listing fee", 99), percentage("Commission", 1000)]

      assert %{lines: [%{name: "Listing fee"}, %{name: "Commission"}]} =
               Deduction.breakdown(rows, 10_000)
    end

    test "reads a net below nothing rather than trimming the rows to fit" do
      rows = [flat("Listing fee", 9000), percentage("Commission", 5000)]

      assert %{total: 14_000, net: -4000} = Deduction.breakdown(rows, 10_000)
    end
  end
end
