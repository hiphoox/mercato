defmodule Mercato.Carts.CartItem.Preparations.DropExpired do
  @moduledoc """
  Keeps a cart to the lines still inside the retention window, and clears out
  the ones that have fallen outside it.

  A cart is read far more often than it is swept, so the read is the sweep:
  there is no scheduler on this platform and nothing to add one for. The
  clear-out is not limited to the cart being read, since the lines most in need
  of going are a visitor's, and a visitor whose token is gone never comes back
  to trigger their own.
  """

  use Ash.Resource.Preparation

  require Ash.Query

  @impl true
  def prepare(query, _opts, _context) do
    cutoff = Mercato.Carts.retention_cutoff()

    query
    |> Ash.Query.before_action(fn query ->
      sweep(cutoff)
      query
    end)
    |> Ash.Query.filter(updated_at >= ^cutoff)
  end

  # Unauthorized on purpose: it drops what nobody may have any more, on behalf
  # of the platform rather than of whoever happened to open their cart.
  defp sweep(cutoff) do
    Mercato.Carts.CartItem
    |> Ash.Query.for_read(:expired, %{cutoff: cutoff}, authorize?: false)
    |> Ash.bulk_destroy!(:remove, %{},
      authorize?: false,
      return_errors?: true,
      allow_stream_with: :full_read
    )
  end
end
