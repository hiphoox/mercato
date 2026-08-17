defmodule Mercato.Accounts.RolePermission do
  @moduledoc """
  Join resource granting a `Permission` to a `Role`.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Accounts,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "role_permissions"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:role_id, :permission_id]
      upsert? true
      upsert_identity :unique_role_permission
    end
  end

  relationships do
    belongs_to :role, Mercato.Accounts.Role do
      primary_key? true
      allow_nil? false
    end

    belongs_to :permission, Mercato.Accounts.Permission do
      primary_key? true
      allow_nil? false
    end
  end

  identities do
    identity :unique_role_permission, [:role_id, :permission_id]
  end
end
