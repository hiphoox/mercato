defmodule Mercato.Listings.ListingImage.Validations.ImageWithinSizeLimit do
  @moduledoc "Refuses an upload larger than this marketplace accepts."

  use Ash.Resource.Validation

  alias Mercato.Listings

  @impl true
  def validate(changeset, _opts, _context) do
    image = Ash.Changeset.get_argument(changeset, :image)
    limit = Listings.image_max_bytes()

    # A missing file is the required-argument check's to report, not this one's.
    if is_nil(image) or byte_size(image) <= limit do
      :ok
    else
      {:error, field: :image, message: "must be no larger than %{limit} bytes", limit: limit}
    end
  end
end
