defmodule Mercato.Accounts.Scope do
  @moduledoc """
  Who is looking, and what that lets them reach.

  Built once per mount or request and carried as a single assign, so a page and
  the chrome around it cannot disagree about who the visitor is. A signed-out
  visitor gets a scope too, rather than none — absent means the caller forgot,
  which is a different thing from nobody being signed in.

  Derived answers live here rather than beside the user, so a question like
  admin access is settled in one place instead of once per page that asks it.

  It carries the visitor's guest token as well as their account, because a
  visitor with no account still gathers a cart and the two have to be told
  apart. Implementing `Ash.Scope.ToOpts` is what lets both travel to an action
  as one `scope:` option rather than as an actor and a context the caller has
  to assemble by hand.
  """

  alias Mercato.Accounts

  @type t :: %__MODULE__{
          user: Accounts.User.t() | nil,
          admin?: boolean(),
          guest_token: String.t() | nil
        }

  defstruct user: nil, admin?: false, guest_token: nil

  @doc """
  Builds the scope for `user`, or for a signed-out visitor when it is nil.

  The guest token is carried whether or not there is an account, since the
  same visitor may sign in mid-visit and what they gathered before then is
  still theirs to claim.
  """
  def for_user(user, guest_token \\ nil)

  def for_user(nil, guest_token), do: %__MODULE__{guest_token: guest_token}

  def for_user(user, guest_token) do
    %__MODULE__{
      user: user,
      admin?: Accounts.can_list_accounts?(user),
      guest_token: guest_token
    }
  end

  defimpl Ash.Scope.ToOpts do
    def get_actor(%{user: user}), do: {:ok, user}

    # Shared, so an action that reads or writes on behalf of another one — the
    # cart's own lookup of the line already there — is still the same visitor.
    def get_context(%{guest_token: guest_token}),
      do: {:ok, %{shared: %{guest_token: guest_token}}}

    def get_tenant(_scope), do: :error
    def get_tracer(_scope), do: :error
    def get_authorize?(_scope), do: :error
  end
end
