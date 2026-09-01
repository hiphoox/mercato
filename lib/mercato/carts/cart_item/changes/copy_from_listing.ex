defmodule Mercato.Carts.CartItem.Changes.CopyFromListing do
  @moduledoc """
  Takes the listing named by the `:listing_id` argument and puts it, and its
  seller, on the line.

  The listing is read as the buyer, so a draft or a paused listing cannot be
  gathered any more than it can be bought.
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

      {:error, _} ->
        Ash.Changeset.add_error(changeset,
          field: :listing_id,
          message: "is not a listing that can be bought"
        )
    end
  end
end
