defmodule Mercato.Accounts.User.Changes.UploadAvatar do
  @moduledoc """
  Stores the uploaded avatar via the configured `Mercato.Ports.Storage`
  adapter and sets `avatar_url` to its public URL.
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      avatar = Ash.Changeset.get_argument(changeset, :avatar)
      filename = Ash.Changeset.get_argument(changeset, :filename)
      user_id = Ash.Changeset.get_attribute(changeset, :id)
      key = "avatars/#{user_id}/#{Ash.UUID.generate()}-#{filename}"
      storage = Application.fetch_env!(:mercato, :storage_adapter)

      case storage.put(key, avatar) do
        {:ok, stored_key} ->
          Ash.Changeset.force_change_attribute(changeset, :avatar_url, storage.url(stored_key))

        {:error, reason} ->
          Ash.Changeset.add_error(changeset,
            field: :avatar,
            message: "could not be uploaded: #{inspect(reason)}"
          )
      end
    end)
  end
end
