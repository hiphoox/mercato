defmodule Mercato.Accounts.Permission do
  @moduledoc """
  A grantable capability, assigned to roles via `role_permissions`.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Accounts,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "permissions"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]
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
