defmodule Mercato.Carts.CartItem do
  @moduledoc """
  One listing a buyer means to buy, in the quantity they mean to buy it in.

  A line holds no price. What a listing costs is the listing's to say until a
  purchase agrees it, so a cart shows what a seller is asking now rather than
  what they were asking when the line was added.

  It belongs either to an account or to a visitor's guest token, never to
  both and never to neither: an account is needed neither to gather a cart nor
  to check one out. Signing in claims the token's lines for the account.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Carts,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Mercato.Carts.CartItem.Changes
  alias Mercato.Carts.CartItem.Preparations

  sqlite do
    table "cart_items"
    repo Mercato.Repo

    references do
      # In the database rather than in the action, so it holds whoever deletes.
      reference :listing, on_delete: :delete
    end
  end

  actions do
    defaults [:read]

    read :line_for_listing do
      description "The buyer's existing line for one listing, if they have one."
      get? true

      argument :listing_id, :uuid do
        allow_nil? false
      end

      filter expr(listing_id == ^arg(:listing_id))

      prepare Preparations.DropExpired
    end

    read :lapsed_for_seller do
      description "The buyer's lines from one seller that have fallen outside the window."

      argument :seller_id, :uuid do
        allow_nil? false
      end

      argument :cutoff, :utc_datetime_usec do
        allow_nil? false
      end

      filter expr(seller_id == ^arg(:seller_id) and updated_at < ^arg(:cutoff))
    end

    read :expired do
      description "Lines left untouched past the retention window, whosever they are."

      argument :cutoff, :utc_datetime_usec do
        allow_nil? false
      end

      filter expr(updated_at < ^arg(:cutoff))
    end

    read :list_mine do
      description "Everything the buyer has gathered, in the order a cart reads."

      prepare Preparations.DropExpired
      prepare build(load: :seller, sort: [seller_id: :asc, inserted_at: :asc])
      prepare &load_carted_listing/2
    end

    read :list_for_seller do
      description "The lines one seller has in the buyer's cart — the group a checkout is for."

      argument :seller_id, :uuid do
        allow_nil? false
      end

      filter expr(seller_id == ^arg(:seller_id))

      prepare Preparations.DropExpired
      prepare build(load: :seller, sort: [inserted_at: :asc])
      prepare &load_carted_listing/2
    end

    create :add do
      description "Puts a listing in the buyer's cart, or adds to the line already there."

      argument :listing_id, :uuid do
        allow_nil? false
      end

      accept [:quantity]

      # The same listing added twice is one line the buyer meant to buy more
      # of, not two lines they have to reconcile by hand. Which identity says
      # so depends on who is buying, so `AttachToBuyer` names it rather than
      # the action, which cannot know.
      upsert? true
      upsert_fields [:quantity]

      change Changes.AttachToBuyer
      change Changes.CopyFromListing
      change Changes.SumWithExistingLine
    end

    update :set_quantity do
      description "Says how many of a line the buyer wants."
      accept [:quantity]
    end

    destroy :remove do
      description "Takes a line out of the cart."
    end
  end

  policies do
    # Whose a new line is is settled by `AttachToBuyer` from the actor and the
    # token, neither of which the caller supplies as an attribute.
    policy action_type(:create) do
      authorize_if always()
    end

    # One rule for reading and for changing, since a line is one person's on
    # both counts: the account's when they are signed in, or the visitor's
    # when it carries the token the line was gathered against.
    #
    # Two checks rather than one `or`, because a check that mentions the actor
    # is refused outright when there is no actor — a visitor would never reach
    # the half of it that is about them. The token is guarded against being
    # absent for the opposite reason: with no token, it must not match every
    # line that has none either.
    #
    # It filters on a read rather than refusing, so a stranger reads an empty
    # cart and somebody else's line reads as absent rather than forbidden.
    policy action_type([:read, :update, :destroy]) do
      authorize_if expr(user_id == ^actor(:id))

      authorize_if expr(
                     not is_nil(^context([:shared, :guest_token])) and
                       guest_token == ^context([:shared, :guest_token])
                   )
    end
  end

  attributes do
    uuid_primary_key :id

    # What tells one visitor's cart from another's before either has an
    # account. Never public: it is a secret the browser holds, not a field a
    # caller sets.
    attribute :guest_token, :string do
      constraints min_length: 1
    end

    attribute :quantity, :integer do
      allow_nil? false
      # A line of none is not an intention to buy; removing it is.
      constraints min: 1
      default 1
      public? true
    end

    timestamps()
  end

  relationships do
    # Nil while the cart is a visitor's. It gains an owner when they sign in,
    # not when they gathered the line.
    belongs_to :user, Mercato.Accounts.User do
      public? true
    end

    belongs_to :listing, Mercato.Listings.Listing do
      allow_nil? false
      public? true
    end

    # Held on the line rather than reached through the listing, so grouping a
    # cart by seller — which is how it is read, and how it will be bought — is
    # a local sort rather than a join.
    belongs_to :seller, Mercato.Accounts.User do
      allow_nil? false
      public? true
    end
  end

  # The listing's cart read, not its ordinary one, which hands back nothing for a
  # line whose listing has since left the marketplace. A function because the
  # query needs the caller, and to keep the listing off this module's compile
  # time dependencies.
  defp load_carted_listing(query, context) do
    listing =
      Ash.Query.for_read(
        Mercato.Listings.Listing,
        :for_cart_line,
        %{},
        Ash.Context.to_opts(context)
      )

    Ash.Query.load(query, listing: listing)
  end

  identities do
    identity :unique_user_listing, [:user_id, :listing_id]

    # A second identity rather than one over both owners: SQLite counts NULLs
    # as distinct in a unique index, so each of these only ever binds the rows
    # that actually have the owner it names.
    identity :unique_guest_listing, [:guest_token, :listing_id]
  end
end
