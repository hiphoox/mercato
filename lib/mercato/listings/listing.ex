defmodule Mercato.Listings.Listing do
  @moduledoc """
  Something a seller publishes for a buyer to buy.

  "Listing" rather than "product" so the same entity covers goods, services,
  and rentals without biasing the starter kit toward retail.
  """

  use Ash.Resource, otp_app: :mercato, domain: Mercato.Listings, data_layer: AshSqlite.DataLayer

  sqlite do
    table "listings"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]

    create :create do
      description "Publishes nothing yet — a new listing starts as the seller's draft."

      # Currency is deliberately not accepted: the instance has one currency,
      # so a listing stamps the configured default rather than choosing.
      accept [:title, :description, :price, :quantity, :condition, :category_id]

      # The seller is the actor, never a client-supplied id: accepting
      # seller_id would let a caller create a listing under someone else's name.
      change relate_actor(:seller)
    end

    update :update do
      accept [:title, :description, :price, :quantity, :condition, :category_id]
    end

    update :publish do
      description "Offers a draft listing to buyers."
      accept []

      validate data_one_of(:status, [:draft])

      # The database has the last word on the state moved from. The validation
      # above reads the copy the caller passed in, which may have been fetched
      # before someone else moved the listing on.
      change filter(expr(status == :draft))

      change set_attribute(:status, :active)

      # Stamped here and nowhere else. Publish is reachable only from a draft,
      # so this records first publication and a later pause leaves it standing.
      change set_attribute(:published_at, &DateTime.utc_now/0)
    end

    update :pause do
      description "Takes a listing off offer without giving it up."
      accept []

      validate data_one_of(:status, [:active])

      # The database has the last word on the state moved from. The validation
      # above reads the copy the caller passed in, which may have been fetched
      # before someone else moved the listing on.
      change filter(expr(status == :active))

      change set_attribute(:status, :unavailable)
    end

    update :resume do
      description "Puts a paused listing back on offer."
      accept []

      validate data_one_of(:status, [:unavailable])

      # The database has the last word on the state moved from. The validation
      # above reads the copy the caller passed in, which may have been fetched
      # before someone else moved the listing on.
      change filter(expr(status == :unavailable))

      change set_attribute(:status, :active)
    end

    update :mark_sold do
      description "Records that a purchase completed. Terminal."
      accept []

      validate data_one_of(:status, [:active])

      # The database has the last word on the state moved from. The validation
      # above reads the copy the caller passed in, which may have been fetched
      # before someone else moved the listing on.
      change filter(expr(status == :active))

      change set_attribute(:status, :sold)
    end

    destroy :destroy do
      description "Removes the listing along with the gallery it owns."
      primary? true
      require_atomic? false

      # Each image is destroyed through its own action rather than by the
      # database, so the file behind it is freed rather than left orphaned.
      # Before the listing, not after: the gallery's rows point at it, and the
      # database refuses to leave them dangling.
      change cascade_destroy(:images, after_action?: false)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
      constraints min_length: 3, max_length: 140
      public? true
    end

    attribute :description, :string do
      constraints max_length: 5_000
      public? true
    end

    # Minor units (cents), never a float: 0.1 + 0.2 != 0.3 in binary floating
    # point, so summing prices or splitting a payout drifts by fractions of a
    # cent. Integer arithmetic is exact, and payment providers take this form.
    attribute :price, :integer do
      allow_nil? false
      # At least one minor unit: a giveaway is not a sale, and a zero price
      # divides through the fee and payout arithmetic downstream.
      constraints min: 1
      public? true
    end

    # Stamped per row rather than read from config at display time, so a price
    # stays self-describing if the instance currency is ever reconfigured.
    attribute :currency, :string do
      allow_nil? false
      default &Mercato.Listings.currency/0
      public? true
    end

    attribute :quantity, :integer do
      allow_nil? false
      # Zero is a real state — the seller has none left — so only negatives
      # are refused.
      constraints min: 0
      default 1
      public? true
    end

    # Nilable regardless of what the marketplace configures: a seller may leave
    # it blank, and a marketplace configuring no conditions simply never sets it.
    attribute :condition, Mercato.Listings.Listing.Condition do
      public? true
    end

    attribute :status, Mercato.Listings.Listing.Status do
      allow_nil? false
      default :draft
      public? true
    end

    # Nil until the listing is first published; retained across a later pause
    # so it records first publication, not the current visibility.
    attribute :published_at, :utc_datetime_usec do
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :seller, Mercato.Accounts.User do
      allow_nil? false
      public? true
    end

    belongs_to :category, Mercato.Listings.Category do
      allow_nil? false
      public? true
    end

    has_many :images, Mercato.Listings.ListingImage do
      sort position: :asc
      public? true
    end
  end
end
