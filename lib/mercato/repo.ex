defmodule Mercato.Repo do
  use Ecto.Repo,
    otp_app: :mercato,
    adapter: Ecto.Adapters.Postgres
end
