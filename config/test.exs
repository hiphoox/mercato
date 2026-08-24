import Config
config :mercato, token_signing_secret: "1ZRKixWCxSwI+xAHYzYncz1/IIBy7fnO"
config :bcrypt_elixir, log_rounds: 1
config :ash, policies: [show_policy_breakdowns?: true]

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :mercato, Mercato.Repo,
  database: Path.join(__DIR__, "../db/mercato_test#{System.get_env("MIX_TEST_PARTITION")}.db"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1,
  queue_target: 5_000,
  queue_interval: 10_000

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mercato, MercatoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "vFLDFmRbVhMbDNRi/Cl87qpYVJmzggwJE0PEXXKZs6aSoVpTUU5uLyw5v9ba55Yj",
  server: false

# Uploads land in a scratch directory the suite owns, so a test never writes
# into the checkout's static assets.
config :mercato, Mercato.Ports.Storage.Local,
  storage_path: Path.join(__DIR__, "../tmp/test_uploads")

# In test we don't send emails
config :mercato, Mercato.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
