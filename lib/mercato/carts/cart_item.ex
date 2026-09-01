defmodule Mercato.Carts.CartItem do
  @moduledoc """
  One listing a buyer means to buy, in the quantity they mean to buy it in.

  A line holds no price. What a listing costs is the listing's to say until a
  purchase agrees it, so a cart shows what a seller is asking now rather than
  what they were asking when the line was added.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Carts,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Mercato.Carts.CartItem.Changes

  sqlite do
    table "cart_items"
    repo Mercato.Repo
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
    end

    read :list_mine do
      description "Everything the buyer has gathered, in the order a cart reads."

      prepare build(
                load: [:seller, listing: [:display_price, images: :url]],
                sort: [seller_id: :asc, inserted_at: :asc]
              )
    end

    create :add do
      description "Puts a listing in the buyer's cart, or adds to the line already there."

      argument :listing_id, :uuid do
        allow_nil? false
      end

      accept [:quantity]

      # The same listing added twice is one line the buyer meant to buy more
      # of, not two lines they have to reconcile by hand.
      upsert? true
      upsert_identity :unique_user_listing
      upsert_fields [:quantity]

      change relate_actor(:user)
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
    # Filtering rather than refusing, so a stranger reads an empty cart and
    # somebody else's line reads as absent rather than forbidden.
    policy action_type(:read) do
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type(:create) do
      authorize_if relating_to_actor(:user)
    end

    policy action_type([:update, :destroy]) do
      authorize_if expr(user_id == ^actor(:id))
    end
  end

  attributes do
    uuid_primary_key :id

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
    belongs_to :user, Mercato.Accounts.User do
      allow_nil? false
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

  identities do
    identity :unique_user_listing, [:user_id, :listing_id]
  end
end
