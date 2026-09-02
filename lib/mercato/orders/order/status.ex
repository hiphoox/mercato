defmodule Mercato.Orders.Order.Status do
  @moduledoc """
  Where an order sits between being bought and being done with.

  An order begins `:placed` — the buyer has paid and the seller owes them
  something. `:fulfilled` is the seller's claim to have sent it, which is what
  opens the buyer's window to confirm. `:completed` and `:cancelled` are
  terminal: money has been released or returned, and there is nothing left to
  move.
  """
  @states [:placed, :fulfilled, :completed, :cancelled]

  use Ash.Type.Enum, values: @states

  @transitions %{
    placed: [:fulfilled, :cancelled],
    fulfilled: [:completed],
    completed: [],
    cancelled: []
  }

  @doc """
  The states an order may move to from each state it can be in.

  Declared here rather than restated at each action, so adding a state forces
  one decision in one place instead of leaving a path silently open or shut
  wherever a guard was missed.
  """
  def transitions, do: @transitions

  @terminal for state <- @states, @transitions[state] == [], do: state

  @doc """
  The states an order stays in once it reaches them.

  Derived from the table above rather than listed again, so a state that later
  gains a way out stops being terminal without anything here being edited.
  """
  def terminal, do: @terminal

  @doc """
  Whether an order may move from `from` to `to`.

  Cancelling is deliberately absent once the seller has fulfilled: what a buyer
  wants at that point is a refund of something already sent, which is a dispute
  rather than a cancellation.
  """
  def can_transition?(from, to), do: to in Map.get(@transitions, from, [])
end
