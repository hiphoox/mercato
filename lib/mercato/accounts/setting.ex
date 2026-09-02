defmodule Mercato.Accounts.Setting do
  @moduledoc """
  Platform-wide, admin-configurable settings.

  A single row holds the current values; there is no per-key lookup because
  there is only ever one row. Read through `get/1` rather than querying the
  resource directly, so a caller gets the platform default when no row has been
  seeded yet.

  These are the values a marketplace tunes to fit what it sells — what it is
  priced in, what a listing may say about itself, how long an intention to buy
  is kept. They live here rather than in a config file so an operator changes
  them from the admin area instead of a deployer changing them from a release.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Accounts,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Mercato.Accounts.User.Checks.ActorHasPermission

  # The platform's own answer for every setting, applying both as the column
  # default and as what `get/1` falls back to before anybody has saved a row.
  # Stated once here so the two can never drift apart.
  @defaults %{
    handle_change_cooldown_days: 30,
    cart_retention_seconds: 30 * 24 * 60 * 60,
    currency: "USD",
    listing_conditions: ["new", "like_new", "good", "fair"],
    listing_image_types: ["image/jpeg", "image/png", "image/webp"],
    listing_image_max_bytes: 5_242_880,
    listing_min_images: 1,
    listing_max_images: 10
  }

  @editable Map.keys(@defaults)

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
      accept @editable
    end

    update :update do
      accept @editable
    end
  end

  policies do
    # Read by everyone, including a visitor with no account: what the
    # marketplace is priced in and what conditions it offers are read on every
    # browse, signed in or not.
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type([:create, :update]) do
      authorize_if {ActorHasPermission, permission: "settings:update"}
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :handle_change_cooldown_days, :integer do
      allow_nil? false
      default @defaults.handle_change_cooldown_days
      public? true
    end

    # How long a line the buyer has not touched stays in their cart. A cart
    # binds nobody, so an intention nobody has revisited in this long is gone
    # rather than kept forever.
    #
    # Held in seconds though an operator sets it in whole days: a window has to
    # be settable in something smaller than a day to be exercised at all.
    attribute :cart_retention_seconds, :integer do
      allow_nil? false
      constraints min: 1
      default @defaults.cart_retention_seconds
      public? true
    end

    # The single currency every price on this instance is denominated in, as an
    # ISO 4217 code.
    attribute :currency, :string do
      allow_nil? false
      constraints min_length: 3, max_length: 3
      default @defaults.currency
      public? true
    end

    # Empty drops the field from every listing, which is what a marketplace of
    # services or digital goods wants.
    attribute :listing_conditions, {:array, :string} do
      allow_nil? false
      default @defaults.listing_conditions
      public? true
    end

    attribute :listing_image_types, {:array, :string} do
      allow_nil? false
      default @defaults.listing_image_types
      public? true
    end

    attribute :listing_image_max_bytes, :integer do
      allow_nil? false
      constraints min: 1
      default @defaults.listing_image_max_bytes
      public? true
    end

    attribute :listing_min_images, :integer do
      allow_nil? false
      constraints min: 0
      default @defaults.listing_min_images
      public? true
    end

    attribute :listing_max_images, :integer do
      allow_nil? false
      constraints min: 1
      default @defaults.listing_max_images
      public? true
    end
  end

  @doc "Every setting an operator may edit."
  def editable, do: @editable

  @doc "The platform's own answer for `key`, before an operator sets one."
  def default(key), do: Map.fetch!(@defaults, key)

  @doc """
  What this instance has set for `key`, or the platform default.

  Unauthorized on purpose: a setting is read on paths that have no actor at
  all, and reading one tells nobody anything the marketplace does not already
  show them.
  """
  def get(key) when key in @editable do
    case Mercato.Accounts.current_settings(authorize?: false, not_found_error?: false) do
      {:ok, %__MODULE__{} = settings} -> Map.fetch!(settings, key)
      _no_row -> default(key)
    end
  end

  @doc "Days a user must wait between handle changes."
  def handle_change_cooldown_days, do: get(:handle_change_cooldown_days)
end
