# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Seed data lives one file per concern under `priv/repo/seeds/`. This script
# only lists them, in the order they must run.

for file <- ["accounts.exs", "fees.exs", "listings.exs"] do
  Code.require_file(Path.join("seeds", file), __DIR__)
end
