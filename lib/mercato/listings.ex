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
end
