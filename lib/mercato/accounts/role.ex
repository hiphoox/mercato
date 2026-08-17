defmodule Mercato.Accounts.Role do
  @moduledoc """
  A role a user can hold (e.g. `trader`, `admin`), granted via `user_roles`
  and carrying permissions via `role_permissions`.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Accounts,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "roles"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]

    read :get_by_name do
      description "Looks up a role by its name"
      get_by :name
    end

    create :create do
      primary? true
      accept [:name, :description]
      upsert? true
      upsert_identity :unique_name
      upsert_fields [:description]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :description, :string do
      public? true
    end
  end

  identities do
    identity :unique_name, [:name]
  end
end
