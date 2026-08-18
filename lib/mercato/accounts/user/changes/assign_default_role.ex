defmodule Mercato.Accounts.User.Changes.AssignDefaultRole do
  @moduledoc """
  Assigns the `trader` role via `user_roles` when a newly created user holds
  no role yet.

  Guards on the user already holding a role rather than the action type, so
  magic link's upsert-on-returning-user (which also runs a `:create`
  changeset) never double-assigns — that would violate `user_roles`'
  composite primary key.
  """

  use Ash.Resource.Change

  alias Mercato.Accounts
  alias Mercato.Accounts.UserRole

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, user ->
      case Ash.load(user, :user_roles, authorize?: false) do
        {:ok, %{user_roles: []}} -> assign_trader(user)
        {:ok, _has_role} -> {:ok, user}
        {:error, error} -> {:error, error}
      end
    end)
  end

  defp assign_trader(user) do
    role = Accounts.get_role_by_name!("trader", authorize?: false)

    case Ash.create(UserRole, %{user_id: user.id, role_id: role.id}, authorize?: false) do
      {:ok, _user_role} -> {:ok, user}
      {:error, error} -> {:error, error}
    end
  end
end
