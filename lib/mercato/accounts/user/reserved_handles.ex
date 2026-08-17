defmodule Mercato.Accounts.User.ReservedHandles do
  @moduledoc """
  Handles that can never be assigned, generated or manually chosen.
  """

  @reserved ~w(admin api www support root mercato help settings deleted)

  def reserved?(handle), do: handle in @reserved
end
