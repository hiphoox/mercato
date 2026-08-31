defmodule Mercato.Discovery.Sort do
  @moduledoc """
  One order the browse grid can be read in, declared rather than written out.

  An order states how the shelf is read where a facet states what is on it,
  which is why the two are declared apart and why clearing the filters leaves
  the order standing. What they share is that both are the marketplace's own
  choice: a vehicle marketplace offers fewest miles, a rentals one soonest
  available, and neither should have to edit the grid to say so.

  A declaration names the columns its own order turns on. What settles two rows
  that tie on those columns is not declared, because getting it wrong is
  invisible until a grid reshuffles between two identical reads — see
  `Mercato.Discovery.order_by/1` for the rule that supplies it.

  The label is data, for the same reason a facet's is: an order this codebase
  never heard of is worded by whoever declared it, while the orders shipped
  here are worded in the web layer so they stay translatable.
  """

  @enforce_keys [:key, :label]
  defstruct [:key, :label, by: []]

  @type t :: %__MODULE__{
          key: atom(),
          label: String.t(),
          by: keyword()
        }

  @doc """
  Builds an order from its declaration.

  An order turning on nothing of its own is the shelf's own resting order —
  the one every other order falls back to when its own columns tie.
  """
  @spec new(keyword()) :: t()
  def new(declaration) do
    %__MODULE__{
      key: fetch!(declaration, :key),
      label: fetch!(declaration, :label),
      by: Keyword.get(declaration, :by, [])
    }
  end

  defp fetch!(declaration, key) do
    case Keyword.fetch(declaration, key) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "a sort declaration needs a #{key}"
    end
  end
end
