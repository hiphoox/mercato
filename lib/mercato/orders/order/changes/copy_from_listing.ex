defmodule Mercato.Orders.Order.Changes.CopyFromListing do
  @moduledoc """
  Takes the listing named by the `:listing_id` argument and copies what the
  purchase agreed onto the order.

  A change rather than declared attributes, because the values come from
  another row: the seller, the price, and the currency are the listing's as it
  stood at the moment of purchase, and none of them is the buyer's to supply.

  The listing is read as the buyer, so an order cannot be placed against one
  the buyer cannot see.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, context) do
    listing_id = Ash.Changeset.get_argument(changeset, :listing_id)

    case Mercato.Listings.get_listing(listing_id, actor: context.actor) do
      {:ok, listing} ->
        changeset
        |> Ash.Changeset.force_change_attribute(:listing_id, listing.id)
        |> Ash.Changeset.force_change_attribute(:seller_id, listing.seller_id)
        |> Ash.Changeset.force_change_attribute(:unit_price, listing.price)
        |> Ash.Changeset.force_change_attribute(:currency, listing.currency)

      {:error, _} ->
        Ash.Changeset.add_error(changeset,
          field: :listing_id,
          message: "is not a listing that can be bought"
        )
    end
  end
end
