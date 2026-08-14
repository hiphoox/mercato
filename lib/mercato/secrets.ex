defmodule Mercato.Secrets do
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
