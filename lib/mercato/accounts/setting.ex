defmodule Mercato.Accounts.Setting do
  @moduledoc """
  Platform-wide, admin-configurable settings.

  A single row holds the current values; there is no per-key lookup because
  there's only ever one setting so far. Read via the helper functions below
  rather than querying the resource directly, so callers get a sane default
  when no row has been seeded yet.
  """

  use Ash.Resource, otp_app: :mercato, domain: Mercato.Accounts, data_layer: AshSqlite.DataLayer

  sqlite do
    table "settings"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]

    read :current do
      description "The single settings row, or nothing when none has been seeded."
      get? true
      prepare build(limit: 1)
    end

    create :create do
      accept [:handle_change_cooldown_days]
    end

    update :update do
      accept [:handle_change_cooldown_days]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :handle_change_cooldown_days, :integer do
      allow_nil? false
      default 30
      public? true
    end
  end

  @default_handle_change_cooldown_days 30

  @doc "Days a user must wait between handle changes."
  def handle_change_cooldown_days do
    case Mercato.Accounts.current_settings(authorize?: false, not_found_error?: false) do
      {:ok, %__MODULE__{handle_change_cooldown_days: days}} -> days
      _no_row -> @default_handle_change_cooldown_days
    end
  end
end
