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

  @has_public_profile [:active, :restricted]

  @doc """
  The statuses an account is still shown to the public under.

  A different question from `can_sign_in/0`, even where the answer currently
  matches: that one asks whether someone may come in, this one asks whether
  strangers may still be shown who they are. A banned account is off the
  marketplace, so its public page goes with it. A deleted one is outside this
  list too, though archival has already taken it out of every read by then.
  """
  def has_public_profile, do: @has_public_profile
end
