defmodule Mercato.Accounts.User.Senders.SendNewUserConfirmationEmail do
  @moduledoc """
  Sends an email for a new user to confirm their email address.
  """

  use AshAuthentication.Sender
  use MercatoWeb, :verified_routes

  import Swoosh.Email

  alias Mercato.Accounts.User.Senders.EmailLayout
  alias Mercato.Mailer

  @impl true
  def send(user, token, opts) do
    new()
    # Sender address is a deployment-config placeholder, not a tracked task.
    |> from({"noreply", "noreply@example.com"})
    |> to(to_string(user.email))
    |> subject(subject(opts))
    |> html_body(body(token, opts))
    |> Mailer.deliver!()
  end

  # `opts[:confirmation_type]` is `:identity_link` when an OAuth2/OIDC
  # sign-in whose email matches this already-registered account is asking
  # to be linked (the strategy's `on_untrusted_email_match :confirm`).
  # Confirming grants that provider login access to this account, so make
  # the copy unambiguous about who is asking and what it does.
  defp subject(opts) do
    case opts[:confirmation_type] do
      :identity_link -> "Confirm linking your #{opts[:provider]} login"
      _ -> "Confirm your email address"
    end
  end

  defp body(token, opts) do
    confirm_url = url(~p"/confirm_new_user/#{token}")

    case opts[:confirmation_type] do
      :identity_link ->
        EmailLayout.render(
          "Confirm linking your #{opts[:provider]} login",
          [
            "Someone signed in with #{opts[:provider]} using your email address and wants to link it to your account."
          ],
          "Confirm linking",
          confirm_url,
          "If this wasn't you, ignore this email — nothing has changed."
        )

      _ ->
        EmailLayout.render(
          "Confirm your email",
          [
            "Click the button below to confirm your email address and finish setting up your account."
          ],
          "Confirm email",
          confirm_url
        )
    end
  end
end
