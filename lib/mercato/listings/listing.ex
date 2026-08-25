defmodule Mercato.Listings.Listing do
  @moduledoc """
  Something a seller publishes for a buyer to buy.

  "Listing" rather than "product" so the same entity covers goods, services,
  and rentals without biasing the starter kit toward retail.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Listings,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshArchival.Resource]

  alias Mercato.Accounts.User.Checks.ActorHasPermission
  alias Mercato.Listings.Listing.Calculations

  sqlite do
    table "listings"
    repo Mercato.Repo
  end

  archive do
    # A seller's delete is a real one, so it opts out: nothing is kept of a
    # listing that never sold. Moderation's is the archiving one.
    exclude_destroy_actions [:destroy]

    # Every read hides archived listings on its own, so a read added later is
    # hidden by default rather than by remembering to say so. The moderation
    # view is the one place the backup can be seen.
    exclude_read_actions [:list_for_moderation]

    # Images are deliberately left alone: they are most of what a report about a
    # listing is actually about, and a restored listing needs them back.
    archive_related []
  end

  actions do
    defaults [:read]

    read :list_for_moderation do
      description "Every listing including those moderation has taken down."
    end

    read :list_mine do
      description "Everything the acting seller has listed, whatever state it is in."

      # "Mine" is meaningless without someone to be, and Ash refuses the read
      # outright when the filter has no actor to resolve — a caller acting as
      # nobody gets an error rather than a silently empty page.
      filter expr(seller_id == ^actor(:id))

      # Newest activity first: this view is the seller's worklist, and an edit
      # or a pause is what makes a listing worth looking at again. The gallery
      # comes along because every row shows its cover.
      prepare build(sort: [updated_at: :desc], load: [:display_price, images: :url])
    end

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

      # Run against the loaded row rather than as one atomic statement. Atomic
      # updates carry ownership as part of the WHERE clause, so an edit by
      # someone else comes back as "this listing changed underneath you" when
      # the honest answer is that it belongs to another seller.
      require_atomic? false
    end

    update :publish do
      description "Offers a draft listing to buyers."
      accept []

      # Counting the gallery is a query, so this cannot be one atomic statement.
      require_atomic? false

      validate data_one_of(:status, [:draft])
      validate Mercato.Listings.Listing.Validations.GalleryMeetsMinimum

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

      # A sold listing is the record of a sale, so it outlives the seller's
      # wish to be rid of it. Checked against the row as well as the copy the
      # caller passed in, which may have been fetched before the sale.
      validate attribute_does_not_equal(:status, :sold)
      change filter(expr(status != :sold))

      # Each image is destroyed through its own action rather than by the
      # database, so the file behind it is freed rather than left orphaned.
      # Before the listing, not after: the gallery's rows point at it, and the
      # database refuses to leave them dangling.
      change cascade_destroy(:images, after_action?: false, action: :remove)
    end

    destroy :moderate_delete do
      description "Takes a listing down while keeping it as an internal backup."
      require_atomic? false

      # Archived rather than destroyed, so the row and its gallery survive for a
      # dispute or for restoring a listing taken down in error. Sold is allowed
      # here precisely because nothing is lost.
      change set_attribute(:status, :deleted)
    end
  end

  policies do
    # Filtering rather than refusing, so a public browse gets the listings on
    # offer instead of an error. A seller sees their own whatever state it is in.
    policy action(:read) do
      authorize_if expr(status == :active)
      authorize_if expr(seller_id == ^actor(:id))
    end

    # Filtering, like :read above — a signed-out visitor gets an empty list
    # rather than an error, which is what the page can actually render.
    policy action(:list_mine) do
      authorize_if expr(seller_id == ^actor(:id))
    end

    # Strict, not the default :filter — someone outside the admin area must be
    # refused outright rather than handed an empty page.
    policy action(:list_for_moderation) do
      access_type :strict
      authorize_if {ActorHasPermission, permission: "admin:access"}
    end

    # The creator becomes the seller, so there has to be one.
    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action([:update, :publish, :pause, :resume]) do
      authorize_if expr(seller_id == ^actor(:id))
    end

    policy action(:destroy) do
      authorize_if expr(seller_id == ^actor(:id))
    end

    # Taking down someone else's listing is moderation, not ownership, so it
    # rides on a permission rather than on who the seller is.
    policy action(:moderate_delete) do
      authorize_if {ActorHasPermission, permission: "listing:delete"}
    end

    # Named on its own so the seller rule above does not also cover it: a
    # listing is sold because a purchase completed, never because someone said
    # so. Only the platform, acting for nobody, may record it.
    policy action(:mark_sold) do
      forbid_if actor_present()
      authorize_if always()
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

  calculations do
    # A calculation rather than a caller's own arithmetic: the price is stored
    # in minor units, and every place a listing is shown needs the same
    # conversion against the currency the listing itself carries.
    calculate :display_price, :string, Calculations.DisplayPrice do
      public? true
    end
  end
end
