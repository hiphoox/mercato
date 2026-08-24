defmodule Mercato.Listings.ListingImage.Validations.GalleryKeepsMinimum do
  @moduledoc """
  Refuses to remove an image that would drop a listing already on offer below
  the number the marketplace requires.
  """

  use Ash.Resource.Validation

  alias Mercato.Listings

  @impl true
  def validate(changeset, _opts, _context) do
    image = changeset.data
    minimum = Listings.min_images()

    # Counted for the listing rather than for the caller: how many images it has
    # does not depend on who is asking.
    gallery = Listings.list_listing_images!(image.listing_id, authorize?: false)

    # Only a listing being offered has anything to protect: a draft is still
    # being composed, and publishing is where the minimum is checked.
    if on_offer?(image) and length(gallery) <= minimum do
      {:error,
       field: :id, message: "would leave a listing on offer with fewer than #{minimum} images"}
    else
      :ok
    end
  end

  defp on_offer?(image) do
    case Ash.load(image, :listing, authorize?: false) do
      {:ok, %{listing: %{status: :active}}} -> true
      _otherwise -> false
    end
  end
end
