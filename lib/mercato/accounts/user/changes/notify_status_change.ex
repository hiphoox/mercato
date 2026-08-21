defmodule Mercato.Accounts.User.Changes.NotifyStatusChange do
  @moduledoc """
  Emails the account holder when an admin moves their account to a new status.

  Sends only on a real transition — setting an account to the status it already
  holds is a no-op, not news.
  """

  use Ash.Resource.Change

  alias Mercato.Accounts.User.Senders.SendAccountStatusEmail

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, user ->
      if user.status != changeset.data.status do
        SendAccountStatusEmail.send(user.email, user.status)
      end

      {:ok, user}
    end)
  end
end
