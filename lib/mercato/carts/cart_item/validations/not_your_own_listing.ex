defmodule Mercato.Carts.CartItem.Validations.NotYourOwnListing do
  @moduledoc """
  Refuses a line on a listing the buyer is the seller of.

  Nobody buys from themselves: a seller gathering their own listing would be
  gathering a purchase that could never be paid out, since the money would be
  going where it came from.

  Reads the seller off the line rather than off the listing, `CopyFromListing`
  having put it there — the listing has been read once already and reading it
  again to ask the same question would be reading it twice.
  """
  use Ash.Resource.Validation

  alias Ash.Error.Changes.InvalidArgument

  @impl true
  def validate(changeset, _opts, context) do
    seller_id = Ash.Changeset.get_attribute(changeset, :seller_id)

    # A visitor with no account is nobody's seller: there is no identity to
    # match against, and signing in is what settles whose the line is.
    if context.actor && context.actor.id == seller_id do
      {:error,
       InvalidArgument.exception(
         field: :listing_id,
         message: "is your own listing"
       )}
    else
      :ok
    end
  end
end
