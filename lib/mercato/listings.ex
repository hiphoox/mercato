defmodule Mercato.Listings do
  @moduledoc """
  Domain for the listing a seller publishes and a buyer buys, together with
  the resources that make one up.
  """

  use Ash.Domain,
    otp_app: :mercato,
    extensions: [AshJsonApi.Domain]

  alias Mercato.Accounts.Setting

  json_api do
    routes do
      base_route "/listings", Mercato.Listings.Listing do
        index :suggest_titles, route: "/suggest"
      end

      base_route "/categories", Mercato.Listings.Category do
        index :suggest, route: "/suggest"
      end
    end
  end

  resources do
    resource Mercato.Listings.Listing do
      define :create_listing, action: :create
      define :update_listing, action: :update
      define :delete_listing, action: :destroy
      define :list_listings, action: :read
      define :browse_listings, action: :browse
      define :suggest_listing_titles, action: :suggest_titles
      define :get_listing, action: :get, get_by: [:id]
      define :get_listing_for_cart_line, action: :for_cart_line, get_by: [:id]
      define :get_listing_by_public_id, action: :get_by_public_id, get_by: [:public_id]
      define :list_seller_listings, action: :list_for_seller, args: [:seller_id]
      define :list_my_listings, action: :list_mine
      define :get_my_listing, action: :get_mine, get_by: [:id]
      define :list_listings_for_moderation, action: :list_for_moderation
      define :moderate_delete_listing, action: :moderate_delete
      define :publish_listing, action: :publish
      define :pause_listing, action: :pause
      define :resume_listing, action: :resume
      define :mark_listing_sold, action: :mark_sold
    end

    resource Mercato.Listings.Category do
      define :create_category, action: :create
      define :list_categories, action: :read
      define :suggest_categories, action: :suggest
    end

    resource Mercato.Listings.ListingImage do
      define :add_listing_image, action: :create
      define :list_listing_images, action: :by_listing, args: [:listing_id]
      define :set_listing_image_cover, action: :set_cover
      define :delete_listing_image, action: :destroy
    end
  end

  @doc """
  The single currency every price on this instance is denominated in.

  One value for the whole marketplace, not a per-listing choice — a listing
  stamps this at creation so its price stays readable if the setting changes.
  """
  def currency, do: Setting.get(:currency)

  @doc """
  The conditions a seller may pick from, in display order.

  Set per instance so the field fits what is being sold: a vehicle marketplace
  replaces the list, and one selling services or digital goods empties it,
  which leaves every listing's condition blank.
  """
  def conditions, do: Setting.get(:listing_conditions)

  @doc """
  How a stored condition reads to a person.

  Here rather than in each page that shows one, so the chip on a listing's
  detail page and the option in the seller's form never word it differently.
  A listing with no condition has nothing to label, which is what lets the
  caller leave the chip out rather than render an empty one.

      iex> Mercato.Listings.condition_label("like_new")
      "Like new"
  """
  def condition_label(nil), do: nil

  def condition_label(condition) when is_binary(condition) do
    condition |> String.replace("_", " ") |> String.capitalize()
  end

  @doc """
  The conditions a buyer may narrow the grid by, already worded.

  Value and wording together, in the order the marketplace lists them, so a
  control offering them needs to know neither how a condition is stored nor
  how it reads.
  """
  def condition_options do
    Enum.map(conditions(), &{&1, condition_label(&1)})
  end

  @doc """
  The catalog a buyer may narrow the grid by, keyed the way a URL names a
  category and worded the way the operator named it.
  """
  def category_options do
    Enum.map(list_categories!(query: [sort: :name]), &{&1.slug, &1.name})
  end

  @doc """
  The image types a listing's gallery accepts.

  Matched against the file's own leading bytes rather than the name it arrives
  under, so renaming a file does not get it past the check.
  """
  def image_types, do: Setting.get(:listing_image_types)

  @doc "The largest image a listing's gallery accepts, in bytes."
  def image_max_bytes, do: Setting.get(:listing_image_max_bytes)

  @doc """
  How few images a listing may go on offer with.

  Zero drops the requirement, which is what a marketplace selling services or
  digital goods wants.
  """
  def min_images, do: Setting.get(:listing_min_images)

  @doc "How many images a listing's gallery holds at most."
  def max_images, do: Setting.get(:listing_max_images)
end
