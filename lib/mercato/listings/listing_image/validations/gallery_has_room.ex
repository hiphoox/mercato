defmodule Mercato.Listings.ListingImage.Validations.GalleryHasRoom do
  @moduledoc "Refuses an image that would take a gallery past the size the marketplace allows."

  use Ash.Resource.Validation

  alias Mercato.Listings

  @impl true
  def validate(changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.get_attribute(:listing_id)
    |> check()
  end

  # A missing listing is the required-attribute check's to report, not this one's.
  defp check(nil), do: :ok

  defp check(listing_id) do
    limit = Listings.max_images()

    # Counted for the listing rather than for the caller: how full a gallery is
    # does not depend on who is asking.
    if length(Listings.list_listing_images!(listing_id, authorize?: false)) < limit do
      :ok
    else
      {:error,
       field: :image, message: "would take the gallery past %{limit} images", limit: limit}
    end
  end
end
