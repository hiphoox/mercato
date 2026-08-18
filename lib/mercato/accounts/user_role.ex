defmodule Mercato.Accounts.UserRole do
  @moduledoc """
  Join resource holding a `Role` for a `User`. v1 constrains every user to
  exactly one role row, enforced at the application/policy layer.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Accounts,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "user_roles"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:user_id, :role_id]
    end
  end

  relationships do
    belongs_to :user, Mercato.Accounts.User do
      primary_key? true
      allow_nil? false
    end

    belongs_to :role, Mercato.Accounts.Role do
      primary_key? true
      allow_nil? false
    end
  end
end
