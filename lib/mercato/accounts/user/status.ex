defmodule Mercato.Accounts.User.Status do
  @moduledoc """
  What an account is currently allowed to do.

  `:active` and `:restricted` can both sign in — a restriction limits what the
  person may do inside the app, it does not lock them out of it. `:banned` and
  `:deleted` cannot sign in at all.
  """
  use Ash.Type.Enum, values: [:active, :restricted, :banned, :deleted]

  @can_sign_in [:active, :restricted]

  @doc """
  The statuses that may hold a session.

  Declared here rather than restated at each sign-in action, so adding a status
  forces one decision in one place instead of silently defaulting to "locked
  out" (or worse, "allowed") wherever a filter was missed.
  """
  def can_sign_in, do: @can_sign_in
end
