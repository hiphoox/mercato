defmodule Mercato.Payments.Deduction do
  @moduledoc """
  One deduction as it stood when something was priced against it.

  The same shape as a configured `Mercato.Payments.SellerDeduction` row, minus
  everything only a stored row needs: no identifier, and what a percentage is a
  percentage of is named rather than pointed at, since a name is what tells two
  rows apart and what a seller reads on the line anyway.

  A copy rather than a reference, so a listing carries the terms it was written
  under. An operator raising the commission tomorrow changes what is deducted
  from what is priced tomorrow, and leaves what is already on offer alone.

  The rows are copied, not the amounts they came to: a seller may reprice, and
  a stored amount would then be arithmetic on a price nobody is asking any
  more. The chain is kept whole for the same reason — a row that is a share of
  another rounds against that row's amount, so flattening the two into one rate
  would round once where the marketplace rounds twice.
  """

  use Ash.TypedStruct

  alias Mercato.Money

  typed_struct do
    field :name, :string, allow_nil?: false
    field :kind, Mercato.Payments.Kind, allow_nil?: false
    field :amount, :integer, constraints: [min: 0]
    field :rate_bp, :integer, constraints: [min: 0, max: 10_000]

    # The name of the row this is a share of. Empty means the sale price, which
    # is what an ordinary commission is a share of.
    field :of, :string
  end

  @doc """
  What `deductions` take off a sale of `sale_price` minor units.

  Returns each row as a line of its own, in the order they are applied, the
  total they come to, and what the seller is left with.

  Nothing is capped: rows adding up to more than the sale read as a net below
  nothing rather than as a number quietly trimmed to fit.
  """
  def breakdown(deductions, sale_price) when is_list(deductions) and is_integer(sale_price) do
    amounts = amounts(deductions, sale_price)
    lines = Enum.map(deductions, &%{name: &1.name, amount: Map.fetch!(amounts, &1.name)})
    total = lines |> Enum.map(& &1.amount) |> Enum.sum()

    %{lines: lines, total: total, net: sale_price - total}
  end

  defp amounts(deductions, sale_price) do
    by_name = Map.new(deductions, &{&1.name, &1})

    Enum.reduce(deductions, %{}, &resolve(&1, by_name, sale_price, &2))
  end

  # A row that is a share of another needs that one's amount first, so the rows
  # are resolved by following what they name rather than by their order. The
  # chain always ends: the table it was copied from refuses one that loops.
  defp resolve(row, by_name, sale_price, amounts) do
    cond do
      Map.has_key?(amounts, row.name) ->
        amounts

      row.kind == :flat ->
        Map.put(amounts, row.name, row.amount)

      is_nil(row.of) ->
        Map.put(amounts, row.name, Money.apply_rate(sale_price, row.rate_bp))

      true ->
        amounts = resolve(Map.fetch!(by_name, row.of), by_name, sale_price, amounts)

        Map.put(amounts, row.name, Money.apply_rate(Map.fetch!(amounts, row.of), row.rate_bp))
    end
  end
end
