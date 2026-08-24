defmodule Mercato.Listings.ListingImage.Changes.DeleteStoredImage do
  @moduledoc """
  Removes the file behind an image once its record is gone, so a deleted
  gallery does not leave its bytes paid for and unreachable.
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    # After the record, not before: a file removed ahead of a delete that then
    # fails would leave a row pointing at nothing, and there is no transaction
    # to roll either back. An orphaned file is the safer of the two outcomes.
    Ash.Changeset.after_action(changeset, fn _changeset, image ->
      storage().delete(image.storage_key)

      {:ok, image}
    end)
  end

  defp storage, do: Application.fetch_env!(:mercato, :storage_adapter)
end
