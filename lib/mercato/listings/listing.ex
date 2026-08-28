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
    extensions: [AshArchival.Resource, AshJsonApi.Resource]

  alias Mercato.Accounts.User.Checks.ActorHasPermission
  alias Mercato.Accounts.User.Status, as: SellerStatus
  alias Mercato.Listings.Listing.{Calculations, PublicId}

  sqlite do
    table "listings"
    repo Mercato.Repo
  end

  json_api do
    type "listing"

    # An allowlist, not a subtraction: a field added later is not exposed until
    # it is named here.
    show_fields([:title])

    derive_filter?(false)
    derive_sort?(false)
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

    read :get do
      description "One listing as its detail page shows it, to whoever may see it."
      get? true

      # No filter of its own: who may see which listing is the read policy's
      # business, and stating it twice would let the two drift apart. A listing
      # the caller may not see comes back as not found rather than as refused,
      # which is what a public page can honestly say.

      # The whole page in one read: the gallery, the seller behind the card, the
      # category the breadcrumb names, and the price already formatted.
      prepare build(load: [:display_price, :seller, :category, images: :url])
    end

    read :get_by_public_id do
      description "One listing as its public URL names it, to whoever may see it."
      get? true

      # Same load as `:get` above: this is the same page reached the way the
      # public reaches it, and the two differ only in what they key on.
      prepare build(load: [:display_price, :seller, :category, images: :url])
    end

    read :browse do
      description "Every listing on offer, as the public browse grid shows them."

      argument :query, :string do
        description "Free-text search over the listing's title and description."
        constraints allow_empty?: true
        allow_nil? false
        default ""
      end

      argument :category_slug, :string do
        description "Narrows the grid to one category, named the way its URL names it."
        constraints allow_empty?: true
        allow_nil? false
        default ""
      end

      argument :sort, Mercato.Listings.Listing.SortOrder do
        description "The order the grid is read in."
        allow_nil? false
        default :newest
      end

      # Minor units, like the column they are compared against, so the web layer
      # reads what a buyer typed and nothing here has to know about decimals.
      # Nil is an open end rather than a bound of zero, which is what lets a
      # buyer state one side of the range and leave the other alone.
      argument :price_min, :integer do
        description "The least a listing may cost, in minor units."
        constraints min: 0
      end

      argument :price_max, :integer do
        description "The most a listing may cost, in minor units."
        constraints min: 0
      end

      # A plain string rather than the `Condition` type: the type refuses a
      # value the marketplace no longer configures, and a stale link should land
      # on an empty grid rather than on an error. Empty is no narrowing, the
      # same way it is for the category above.
      argument :condition, :string do
        description "Narrows the grid to one of the conditions the marketplace configures."
        constraints allow_empty?: true
        allow_nil? false
        default ""
      end

      # A disjunction over the two columns rather than a search against them
      # joined: concatenating columns is not compilable to SQLite at all. The
      # match is case-insensitive; see the expression module for why contains/2
      # is unusable here. An empty term matches everything, which is what makes
      # the unsearched grid and a cleared search the same read.
      filter expr(
               (icontains(title, ^arg(:query)) or icontains(description, ^arg(:query))) and
                 (^arg(:category_slug) == "" or category.slug == ^arg(:category_slug)) and
                 (is_nil(^arg(:price_min)) or price >= ^arg(:price_min)) and
                 (is_nil(^arg(:price_max)) or price <= ^arg(:price_max)) and
                 (^arg(:condition) == "" or condition == ^arg(:condition))
             )

      prepare build(load: [:display_price, :seller, images: :url])
      prepare Mercato.Listings.Listing.Preparations.SortOrder
    end

    read :suggest_titles do
      description "Titles matching a term, as the search box completes them."

      argument :query, :string do
        constraints allow_empty?: true
        allow_nil? true
        default ""
      end

      argument :category_slug, :string do
        constraints allow_empty?: true
        allow_nil? true
        default ""
      end

      filter expr(
               icontains(title, ^arg(:query)) and
                 (^arg(:category_slug) == "" or category.slug == ^arg(:category_slug))
             )

      # Over-fetched, then folded down to one per title by the preparation.
      prepare build(sort: [published_at: :desc, inserted_at: :desc], limit: 20)
      prepare Mercato.Listings.Listing.Preparations.DistinctTitles
    end

    read :list_for_seller do
      description "One seller's listings as their public profile shows them."

      argument :seller_id, :uuid do
        allow_nil? false
      end

      filter expr(seller_id == ^arg(:seller_id))

      # Which of the seller's listings a visitor may see is the read policy's
      # business, so the filter here only names whose profile is being read.

      # Newest first within each state; the page groups them, and it draws a
      # card per listing, so the cover and the formatted price come along.
      prepare build(sort: [updated_at: :desc], load: [:display_price, images: :url])
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

    read :get_mine do
      description "One listing the acting seller owns, whatever state it is in."
      get? true

      filter expr(seller_id == ^actor(:id))

      # The form renders the gallery and the price as the seller last saw them.
      prepare build(load: [:display_price, images: :url])
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

      # Counting the gallery is a query, so this cannot be one atomic statement.
      require_atomic? false

      validate data_one_of(:status, [:unavailable])

      # The same bar publishing has to clear, because this is the same move: a
      # listing going back in front of buyers. The minimum guards a listing on
      # offer, so a paused one may lose photos while it is off it.
      validate Mercato.Listings.Listing.Validations.GalleryMeetsMinimum

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
    # A listing is only as public as the account behind it: a seller the
    policy action([:read, :get, :get_by_public_id]) do
      authorize_if expr(status == :active and seller.status in ^SellerStatus.has_public_profile())
      authorize_if expr(seller_id == ^actor(:id))
    end

    # Deliberately without the "or it is mine" clause the reads above carry. The
    # browse grid is the marketplace as a stranger sees it, so a seller browsing
    # it must not find their own drafts and paused listings mixed into the shelf
    policy action([:browse, :suggest_titles]) do
      authorize_if expr(status == :active and seller.status in ^SellerStatus.has_public_profile())
    end

    # Deliberately narrower than the seller's own view and wider than the detail
    # page: a public profile shows what is on offer and what has sold, and shows
    # the same thing to the seller as to a stranger, because it is a preview of
    # what buyers see. A paused or draft listing appears nowhere — the seller
    # took it out of public view, or never put it in.
    #
    # Gated on the seller's status like the reads above, so a profile page that
    # somehow gets rendered for an account off the marketplace has nothing to
    # show — the listings go when the profile does.
    policy action(:list_for_seller) do
      authorize_if expr(
                     status in [:active, :sold] and
                       seller.status in ^SellerStatus.has_public_profile()
                   )
    end

    # Filtering, like :read above — a signed-out visitor gets an empty list
    # rather than an error, which is what the page can actually render.
    policy action([:list_mine, :get_mine]) do
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

    # The identifier the public URL is built from, distinct from the primary
    # key so a shared link stays short and the internal key stays internal.
    # Absent from every action's `accept`, so nothing can supply or change one:
    # a listing keeps the id it was minted with, and links survive every edit.
    attribute :public_id, :string do
      allow_nil? false
      default &PublicId.generate/0
      public? true
    end

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

    timestamps()
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

  identities do
    # A minted id is random rather than checked, so the database is what makes
    # two listings sharing one an error instead of a silent collision.
    identity :unique_public_id, [:public_id]
  end
end

# Lets `~p"/listings/#{listing}"` be the only thing a caller writes: the slug is
# the listing's public name, and nowhere outside this file has to know it is not
# the primary key.
defimpl Phoenix.Param, for: Mercato.Listings.Listing do
  defdelegate to_param(listing), to: Mercato.Listings.Listing.Slug, as: :slug
end
