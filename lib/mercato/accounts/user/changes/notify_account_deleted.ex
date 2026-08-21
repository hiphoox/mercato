defmodule Mercato.Accounts.User.Changes.NotifyAccountDeleted do
  @moduledoc """
  Emails the account holder that their account was deleted, whether they deleted
  it themselves or an admin did.

  Reads the address off the pre-action row: anonymisation replaces the email
  with a placeholder at an undeliverable domain, so the record handed back after
  the write no longer knows where to write to.
  """

  use Ash.Resource.Change

  alias Mercato.Accounts.User.Senders.SendAccountStatusEmail

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, user ->
      SendAccountStatusEmail.send(changeset.data.email, :deleted)

      {:ok, user}
    end)
  end
end
