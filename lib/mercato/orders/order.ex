defmodule Mercato.Orders.Order do
  @moduledoc """
  One buyer's purchase of one seller's listing.

  The order owns what was bought and where it has got to. What happens to the
  money is the payments area's, and how the goods travel is the shipping
  area's, so a marketplace that charges nothing or ships nothing still has
  orders that look like this.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Orders,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Mercato.Accounts.User.Checks.ActorHasPermission
  alias Mercato.Orders.Order.Changes

  sqlite do
    table "orders"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]

    read :get do
      description "One order, to whoever is party to it."
      get? true
    end

    read :get_by_public_id do
      description "One order as its URL names it, to whoever is party to it."
      get? true
    end

    create :place do
      description "Records a buyer's purchase of a listing."

      argument :listing_id, :uuid do
        allow_nil? false
      end

      # Quantity is all the buyer decides. The seller, the price, and the
      # currency come off the listing, and the buyer is whoever is acting.
      accept [:quantity]

      change relate_actor(:buyer)
      change Changes.CopyFromListing
    end
  end

  policies do
    # Filtering rather than refusing, so a stranger's list comes back empty and
    # an order they are not party to reads as absent rather than forbidden.
    policy action_type(:read) do
      authorize_if expr(buyer_id == ^actor(:id))
      authorize_if expr(seller_id == ^actor(:id))

      # An order is what a dispute or a refund is argued over, so moderation
      # sees every one whoever the parties are.
      authorize_if {ActorHasPermission, permission: "admin:access"}
    end

    # The buyer is the actor, so there has to be one.
    policy action_type(:create) do
      authorize_if actor_present()
    end
  end

  attributes do
    uuid_primary_key :id

    # The identifier the order's URL is built from, distinct from the primary
    # key so the internal key never leaves the server and this one stays free to
    # be re-minted. Absent from every action's `accept`, so nothing can supply
    # one.
    attribute :public_id, :uuid do
      allow_nil? false
      default &Ash.UUID.generate/0
      public? true
    end

    attribute :quantity, :integer do
      allow_nil? false
      # Unlike a listing's, an order's quantity has no meaningful zero: buying
      # none of something is not a purchase.
      constraints min: 1
      default 1
      public? true
    end

    # The listing's price as it stood at purchase, copied rather than read back
    # through the relationship, so a seller repricing cannot rewrite what was
    # agreed. Minor units, like the listing column it is copied from.
    attribute :unit_price, :integer do
      allow_nil? false
      constraints min: 1
      public? true
    end

    # Copied alongside the price, and for the same reason: the two are only
    # meaningful together, and an instance reconfigured later must not change
    # what an old order says was paid.
    attribute :currency, :string do
      allow_nil? false
      public? true
    end

    attribute :status, Mercato.Orders.Order.Status do
      allow_nil? false
      default :placed
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :buyer, Mercato.Accounts.User do
      allow_nil? false
      public? true
    end

    # Held on the order rather than reached through the listing, so an order
    # says who owes the buyer without a join, and so a purchase spanning two
    # sellers is refused by the shape of the record rather than by a rule.
    belongs_to :seller, Mercato.Accounts.User do
      allow_nil? false
      public? true
    end

    belongs_to :listing, Mercato.Listings.Listing do
      allow_nil? false
      public? true
    end
  end

  calculations do
    # Derived rather than stored: a total that is written down can disagree
    # with the two numbers it came from, and this one never can.
    calculate :total_price, :integer, expr(quantity * unit_price) do
      public? true
    end
  end

  identities do
    # 122 bits of randomness make a collision unreachable in practice; the index
    # is what keeps that a fact rather than an assumption.
    identity :unique_public_id, [:public_id]
  end
end
