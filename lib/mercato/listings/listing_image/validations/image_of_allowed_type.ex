defmodule Mercato.Listings.ListingImage.Validations.ImageOfAllowedType do
  @moduledoc """
  Refuses an upload whose own bytes are not one of the types this marketplace
  accepts.
  """

  use Ash.Resource.Validation

  alias Mercato.Listings
  alias Mercato.Listings.ListingImage.ContentType

  @impl true
  def validate(changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.get_argument(:image)
    |> check()
  end

  # A missing file is the required-argument check's to report, not this one's.
  defp check(nil), do: :ok

  defp check(image) do
    with {:ok, type} <- ContentType.detect(image),
         true <- type in Listings.image_types() do
      :ok
    else
      _refused -> {:error, field: :image, message: "is not an accepted image type"}
    end
  end
end
