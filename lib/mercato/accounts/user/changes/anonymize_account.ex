defmodule Mercato.Accounts.User.Changes.AnonymizeAccount do
  @moduledoc """
  Erases an account's personal data as part of its archival, and revokes the
  tokens that could still authenticate it.

  AshArchival turns the destroy into a soft destroy — an update that stamps
  `archived_at` — so the attributes set here persist on the surviving row. What
  is left behind records that an account was there, holding nothing that
  identifies who it belonged to.
  """

  use Ash.Resource.Change

  alias AshAuthentication.{Info, Strategy}

  # Reserved by RFC 2606, so the placeholder address can never reach a mailbox.
  @anonymous_email_domain "deleted.invalid"

  @impl true
  def change(changeset, _opts, context) do
    changeset
    |> erase_personal_data()
    |> Ash.Changeset.after_action(fn changeset, user ->
      delete_avatar_blob(changeset.data.avatar_key)

      with :ok <- log_out_everywhere(changeset.resource, user, context) do
        {:ok, user}
      end
    end)
  end

  defp erase_personal_data(changeset) do
    Ash.Changeset.force_change_attributes(changeset, %{
      # Replaced rather than cleared: email is non-nilable and unique. Scoping
      # the placeholder to the id satisfies the identity while releasing the
      # original address for a fresh registration.
      email: "deleted-#{changeset.data.id}@#{@anonymous_email_domain}",
      first_name: nil,
      last_name: nil,
      handle: nil,
      avatar_url: nil,
      avatar_key: nil,
      hashed_password: nil,
      confirmed_at: nil,
      status: :deleted
    })
  end

  # Read off the pre-action data — the attribute has already been nulled, and
  # the blob is only reachable through the key the row held before.
  defp delete_avatar_blob(nil), do: :ok

  defp delete_avatar_blob(key) do
    storage = Application.fetch_env!(:mercato, :storage_adapter)
    storage.delete(key)
  end

  # The account can no longer sign in, but a token issued before deletion would
  # keep authenticating until it expired. Goes through the `log_out_everywhere`
  # add-on already configured on the resource rather than touching the token
  # resource directly.
  defp log_out_everywhere(resource, user, context) do
    resource
    |> Info.strategy!(:log_out_everywhere)
    |> Strategy.action(:log_out_everywhere, %{user: user}, Ash.Context.to_opts(context))
  end
end
