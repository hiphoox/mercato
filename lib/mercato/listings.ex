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
      define :publish_listing, action: :publish
      define :pause_listing, action: :pause
      define :resume_listing, action: :resume
      define :mark_listing_sold, action: :mark_sold
    end

    resource Mercato.Listings.Category do
      define :create_category, action: :create
      define :list_categories, action: :read
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
end
