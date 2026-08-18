defmodule Mercato.Accounts.User.Preparations.StampLastActiveAt do
  @moduledoc """
  Stamps `last_active_at` on the signed-in user after a successful sign-in.
  """

  use Ash.Resource.Preparation

  @impl true
  def prepare(query, _opts, _context) do
    Ash.Query.after_action(query, fn _query, records ->
      {:ok,
       Enum.map(records, fn record ->
         Ash.update!(record, %{}, action: :bump_last_active_at, authorize?: false)
       end)}
    end)
  end
end
