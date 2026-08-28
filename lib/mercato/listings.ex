defmodule Mercato.Listings do
  @moduledoc """
  Domain for the listing a seller publishes and a buyer buys, together with
  the resources that make one up.
  """

  use Ash.Domain,
    otp_app: :mercato

  resources do
    resource Mercato.Listings.Listing do
      define :create_listing, action: :create
      define :update_listing, action: :update
      define :delete_listing, action: :destroy
      define :list_listings, action: :read
      define :browse_listings, action: :browse
      define :suggest_listing_titles, action: :suggest_titles
      define :get_listing, action: :get, get_by: [:id]
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

  @default_currency "USD"

  @doc """
  The single currency every price on this instance is denominated in.

  One value for the whole marketplace, not a per-listing choice — a listing
  stamps this at creation so its price stays readable if the setting changes.
  """
  def currency, do: Application.get_env(:mercato, :currency, @default_currency)

  @default_conditions ["new", "like_new", "good", "fair"]

  @doc """
  The conditions a seller may pick from, in display order.

  Configurable per instance so the field fits what is being sold: a vehicle
  marketplace replaces the list, and one selling services or digital goods
  sets it to `[]`, which leaves every listing's condition blank.
  """
  def conditions, do: Application.get_env(:mercato, :listing_conditions, @default_conditions)

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

  @default_image_types ["image/jpeg", "image/png", "image/webp"]

  @doc """
  The image types a listing's gallery accepts.

  Matched against the file's own leading bytes rather than the name it arrives
  under, so renaming a file does not get it past the check.
  """
  def image_types, do: Application.get_env(:mercato, :listing_image_types, @default_image_types)

  @default_image_max_bytes 5_242_880

  @doc "The largest image a listing's gallery accepts, in bytes."
  def image_max_bytes do
    Application.get_env(:mercato, :listing_image_max_bytes, @default_image_max_bytes)
  end

  @default_min_images 1

  @doc """
  How few images a listing may go on offer with.

  Zero drops the requirement, which is what a marketplace selling services or
  digital goods wants.
  """
  def min_images, do: Application.get_env(:mercato, :listing_min_images, @default_min_images)

  @default_max_images 10

  @doc "How many images a listing's gallery holds at most."
  def max_images, do: Application.get_env(:mercato, :listing_max_images, @default_max_images)
end
