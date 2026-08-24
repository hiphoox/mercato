ExUnit.start()

# Uploads written by the suite start from empty each run, so one run's files
# can never satisfy the next run's assertions.
:mercato
|> Application.fetch_env!(Mercato.Ports.Storage.Local)
|> Keyword.fetch!(:storage_path)
|> File.rm_rf!()

# Seeded once, outside the sandbox, so every per-test transaction (which
# starts from committed DB state) sees the roles register_with_password /
# sign_in_with_magic_link assign by default. Mirrors priv/repo/seeds.exs.
Ecto.Adapters.SQL.Sandbox.mode(Mercato.Repo, :auto)

Ash.create!(Mercato.Accounts.Role, %{name: "trader", description: "Buy + sell"},
  authorize?: false
)

Ash.create!(
  Mercato.Accounts.Role,
  %{name: "admin", description: "Platform staff, full access"},
  authorize?: false
)

Ecto.Adapters.SQL.Sandbox.mode(Mercato.Repo, :manual)
