defmodule Mercato.Accounts.User.Senders.SendPasswordResetEmail do
  @moduledoc """
  Sends a password reset email
  """

  use AshAuthentication.Sender
  use MercatoWeb, :verified_routes

  import Swoosh.Email

  alias Mercato.Accounts.User.Senders.EmailLayout
  alias Mercato.Mailer

  @impl true
  def send(user, token, _) do
    new()
    # Sender address is a deployment-config placeholder, not a tracked task.
    |> from({"noreply", "noreply@example.com"})
    |> to(to_string(user.email))
    |> subject("Reset your password")
    |> html_body(body(token: token))
    |> Mailer.deliver!()
  end

  defp body(params) do
    reset_url = url(~p"/password-reset/#{params[:token]}")

    EmailLayout.render(
      "Reset your password",
      ["Click the button below to choose a new password."],
      "Reset password",
      reset_url,
      "If you didn't request this, you can safely ignore this email — your password won't change."
    )
  end
end
