defmodule Mercato.Secrets do
  @moduledoc """
  Resolves signing secrets for `ash_authentication` (e.g. the token signing
  secret for `Mercato.Accounts.User`).
  """

  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        Mercato.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:mercato, :token_signing_secret)
  end
end
