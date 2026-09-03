defmodule Mercato.Payments.Kind do
  @moduledoc """
  Whether a configured row is a fixed amount or a rate.

  A `:flat` row takes the same amount off every sale, whatever the sale came
  to. A `:percentage` row takes a share of something else — the sale price, or
  another row's amount — so what it takes moves with the sale.

  Shared by what the platform deducts from a seller and what it adds for a
  buyer: the two sit on opposite sides of a sale but are written the same way.
  """
  use Ash.Type.Enum, values: [:flat, :percentage]
end
