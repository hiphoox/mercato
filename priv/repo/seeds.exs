# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Mercato.Repo.insert!(%Mercato.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Mercato.Accounts.Role

Ash.create!(Role, %{name: "trader", description: "Buy + sell"}, authorize?: false)
Ash.create!(Role, %{name: "admin", description: "Platform staff, full access"}, authorize?: false)
