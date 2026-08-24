defmodule Mercato.Listings.Listing.Validations.GalleryMeetsMinimum do
  @moduledoc """
  Refuses to offer a listing showing fewer images than the marketplace requires.
  """

  use Ash.Resource.Validation

  alias Mercato.Listings

  @impl true
  def validate(changeset, _opts, _context) do
    minimum = Listings.min_images()

    if length(gallery(changeset.data.id)) >= minimum do
      :ok
    else
      {:error, field: :images, message: "must number at least #{minimum} to go on offer"}
    end
  end

  # Counted for the listing rather than for the caller. How many images a
  # listing has is a fact about the listing; asked as the caller, someone who
  # cannot see the gallery would be told it is empty.
  defp gallery(listing_id), do: Listings.list_listing_images!(listing_id, authorize?: false)
end
