defmodule Mercato.Accounts.User.Senders.SendAccountStatusEmail do
  @moduledoc """
  Tells an account holder that their account changed status — suspended,
  restricted, restored, or deleted.

  Takes the address rather than the user record, because deletion erases the
  email as part of anonymising the row: the caller has to hand over the address
  it read before the write.
  """

  use MercatoWeb, :verified_routes

  import Swoosh.Email

  alias Mercato.Accounts.User.Senders.EmailLayout
  alias Mercato.Mailer

  require Logger

  @doc """
  Sends the notice for `status` to `email`.

  Returns `:ok` even when delivery fails. The status change has already been
  written by the time this runs, and SQLite has no transaction to roll back —
  raising here would report a failure for something that did happen.
  """
  def send(email, status) do
    {subject, heading, paragraphs, footer} = content(status)

    new()
    # Sender address is a deployment-config placeholder, not a tracked task.
    |> from({"noreply", "noreply@example.com"})
    |> to(to_string(email))
    |> subject(subject)
    |> html_body(EmailLayout.render(heading, paragraphs, "Go to Mercato", url(~p"/"), footer))
    |> Mailer.deliver()
    |> case do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("could not send #{status} account email: #{inspect(reason)}")
        :ok
    end
  end

  defp content(:banned) do
    {"Your Mercato account has been suspended", "Your account has been suspended",
     [
       "You can no longer sign in to Mercato, and your listings are no longer visible to other members.",
       "If you believe this was a mistake, reply to this email and we'll take another look."
     ], nil}
  end

  defp content(:restricted) do
    {"Your Mercato account has been restricted", "Your account has been restricted",
     [
       "You can still sign in and browse Mercato, but some actions are unavailable for now.",
       "If you believe this was a mistake, reply to this email and we'll take another look."
     ], nil}
  end

  defp content(:active) do
    {"Your Mercato account has been restored", "Your account has been restored",
     [
       "The limits on your account have been lifted. You can sign in and use Mercato as normal again.",
       "Thanks for your patience."
     ], nil}
  end

  defp content(:deleted) do
    {"Your Mercato account has been deleted", "Your account has been deleted",
     [
       "Your name, handle, photo, and email have been erased from Mercato, and you can no longer sign in.",
       "Your past orders stay on record for accounting and dispute resolution, without your details attached."
     ], "This cannot be undone. You are welcome to sign up again with the same email address."}
  end
end
