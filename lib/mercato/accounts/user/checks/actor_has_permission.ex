defmodule Mercato.Accounts.User.Checks.ActorHasPermission do
  @moduledoc """
  Policy check: does the actor hold a role granted the given permission
  (via `user_roles` -> `role_permissions` -> `permissions`)?
  """

  use Ash.Policy.SimpleCheck

  require Ash.Query

  alias Mercato.Accounts.RolePermission

  @impl true
  def describe(opts), do: "actor has the #{inspect(opts[:permission])} permission"

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(actor, _context, opts) do
    permission_name = to_string(opts[:permission])

    # One query, not a role lookup followed by a permission lookup: this runs on
    # every authenticated LiveView mount (the sidebar asks whether to show the
    # Admin section), so the round trip is worth collapsing.
    RolePermission
    |> Ash.Query.filter(
      permission.name == ^permission_name and
        exists(role.user_roles, user_id == ^actor.id)
    )
    |> Ash.Query.limit(1)
    |> Ash.read!(authorize?: false)
    |> Enum.any?()
  end
end
