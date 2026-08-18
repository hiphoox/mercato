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
    role_ids =
      actor
      |> Ash.load!(:user_roles, authorize?: false)
      |> Map.fetch!(:user_roles)
      |> Enum.map(& &1.role_id)

    permission_name = to_string(opts[:permission])

    RolePermission
    |> Ash.Query.filter(role_id in ^role_ids)
    |> Ash.Query.load(:permission)
    |> Ash.read!(authorize?: false)
    |> Enum.any?(&(&1.permission.name == permission_name))
  end
end
