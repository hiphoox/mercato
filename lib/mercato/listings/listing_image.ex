defmodule Mercato.Listings.ListingImage do
  @moduledoc """
  One photo in a listing's gallery.

  The gallery is ordered and has a cover — the single image that represents the
  listing wherever only one can be shown. Both are derived rather than supplied:
  an image is appended behind the ones already there, and the first image a
  listing gets becomes its cover.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Listings,
    data_layer: AshSqlite.DataLayer

  alias Mercato.Listings.ListingImage.{Changes, Validations}

  sqlite do
    table "listing_images"
    repo Mercato.Repo

    custom_indexes do
      # At most one cover per listing, refused by the database rather than by
      # application code. A partial index constrains only the covering rows, so
      # the listing's other images are free to share a listing_id.
      index [:listing_id], unique: true, where: "is_cover", name: "listing_images_cover_index"
    end
  end

  actions do
    defaults [:read]

    create :create do
      description "Uploads a file and adds it to the end of a listing's gallery."

      # The key is not accepted either: it names a place in storage that only
      # the upload itself can know, so a caller supplying one would be pointing
      # the record at a file it never wrote.
      accept [:listing_id]

      argument :image, :binary do
        allow_nil? false
      end

      argument :filename, :string do
        allow_nil? false
      end

      validate Validations.ImageWithinSizeLimit
      validate Validations.ImageOfAllowedType
      validate Validations.GalleryHasRoom

      # Position and cover are the gallery's business, not the caller's: both
      # are decided from what the listing already holds.
      change Changes.PlaceInGallery
      change Changes.StoreImage
    end

    read :by_listing do
      description "A listing's images in gallery order."

      argument :listing_id, :uuid, allow_nil?: false

      filter expr(listing_id == ^arg(:listing_id))

      prepare build(sort: [position: :asc])
    end

    update :set_cover do
      description "Makes this the image that represents the listing."

      accept []
      require_atomic? false

      change Changes.MakeSoleCover
    end

    # Internal to `set_cover`: the old cover has to step down before the new one
    # takes the slot, or the unique index refuses the pair.
    update :demote_cover do
      accept []
      require_atomic? false

      change set_attribute(:is_cover, false)
    end

    destroy :destroy do
      primary? true
      require_atomic? false

      validate Validations.GalleryKeepsMinimum

      change Changes.PromoteNextCover
      change Changes.DeleteStoredImage
    end

    # Used when the listing itself is going. The minimum has nothing left to
    # protect and there is no gallery left to hand the cover on to, so neither
    # applies — but the file still has to go.
    destroy :remove do
      require_atomic? false

      change Changes.DeleteStoredImage
    end
  end

  attributes do
    uuid_primary_key :id

    # The key the blob is stored under, not a URL: a URL cannot be turned back
    # into one without knowing the adapter that built it.
    attribute :storage_key, :string do
      allow_nil? false
      public? true
    end

    # Zero-based, so the front of the gallery is position zero.
    attribute :position, :integer do
      allow_nil? false
      constraints min: 0
      public? true
    end

    attribute :is_cover, :boolean do
      allow_nil? false
      default false
      public? true
    end

    create_timestamp :created_at
  end

  relationships do
    belongs_to :listing, Mercato.Listings.Listing do
      allow_nil? false
      public? true
    end
  end

  identities do
    # Two images cannot share a slot, so a gallery always has a definite order.
    identity :unique_position, [:listing_id, :position]
  end
end
