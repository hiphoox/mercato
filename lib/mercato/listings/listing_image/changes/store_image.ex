defmodule Mercato.Listings.ListingImage.Changes.StoreImage do
  @moduledoc """
  Writes the uploaded file through the configured storage port and records the
  key it went to.
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      image = Ash.Changeset.get_argument(changeset, :image)
      key = storage_key(changeset)

      case storage().put(key, image) do
        {:ok, stored_key} ->
          Ash.Changeset.force_change_attribute(changeset, :storage_key, stored_key)

        {:error, reason} ->
          Ash.Changeset.add_error(changeset,
            field: :image,
            message: "could not be uploaded: #{inspect(reason)}"
          )
      end
    end)
  end

  defp storage_key(changeset) do
    listing_id = Ash.Changeset.get_attribute(changeset, :listing_id)

    # Only the last segment of the name is kept, so a filename carrying a path
    # cannot aim the key outside the listing's own folder. The uuid keeps two
    # uploads of the same name apart.
    filename =
      changeset
      |> Ash.Changeset.get_argument(:filename)
      |> Path.basename()

    "listings/#{listing_id}/#{Ash.UUID.generate()}-#{filename}"
  end

  defp storage, do: Application.fetch_env!(:mercato, :storage_adapter)
end
