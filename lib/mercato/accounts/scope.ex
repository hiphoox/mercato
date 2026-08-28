defmodule Mercato.Accounts.Scope do
  @moduledoc """
  Who is looking, and what that lets them reach.

  Built once per mount or request and carried as a single assign, so a page and
  the chrome around it cannot disagree about who the visitor is. A signed-out
  visitor gets a scope too, rather than none — absent means the caller forgot,
  which is a different thing from nobody being signed in.

  Derived answers live here rather than beside the user, so a question like
  admin access is settled in one place instead of once per page that asks it.
  """

  alias Mercato.Accounts

  @type t :: %__MODULE__{user: Accounts.User.t() | nil, admin?: boolean()}

  defstruct user: nil, admin?: false

  @doc "Builds the scope for `user`, or for a signed-out visitor when it is nil."
  def for_user(nil), do: %__MODULE__{}

  def for_user(user), do: %__MODULE__{user: user, admin?: Accounts.can_list_accounts?(user)}
end
