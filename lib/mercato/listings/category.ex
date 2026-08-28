defmodule Mercato.Listings.Category do
  @moduledoc """
  One entry in the catalog a seller files a listing under.

  A flat, seeded list: the marketplace decides what it sells by replacing the
  seed data, not by letting sellers invent categories as they go.
  """

  use Ash.Resource, otp_app: :mercato, domain: Mercato.Listings, data_layer: AshSqlite.DataLayer

  sqlite do
    table "categories"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]

    read :suggest do
      description "Categories whose name matches a term, as the search box offers them."

      argument :query, :string do
        constraints allow_empty?: true
        allow_nil? false
        default ""
      end

      filter expr(icontains(name, ^arg(:query)))

      prepare build(sort: [:name], limit: 5)
    end

    create :create do
      primary? true
      accept [:name, :slug]

      # Upserts so the seed file can be re-run: a marketplace editing its
      # catalog reruns the seeds and gets renames, not duplicate rows.
      upsert? true
      upsert_identity :unique_slug
      upsert_fields [:name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    # The stable identifier: it appears in browse URLs and is what the seeds
    # match on, so a category can be renamed without breaking either.
    attribute :slug, :string do
      allow_nil? false
      public? true
    end
  end

  relationships do
    has_many :listings, Mercato.Listings.Listing
  end

  identities do
    identity :unique_slug, [:slug]
  end
end
