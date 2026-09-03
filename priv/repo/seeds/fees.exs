# Fees seeds: sample rows for what the marketplace takes off a seller. Loaded
# by `priv/repo/seeds.exs`, before the listings that copy them.
#
# Dev only, and deliberately so: a fresh install charges nothing, and a
# deployment decides what it charges from the admin area rather than inheriting
# a rate seeded here. Locally the rows are what make the payout breakdown on the
# sell form and the fee tables in the admin area have anything to show.
#
# What a buyer pays on top is left empty. Nothing charges a buyer fee yet, so a
# seeded row would state a charge no checkout applies.

if Mix.env() == :dev do
  alias Mercato.Payments

  # One row of each shape a deduction may take: a flat amount, a share of the
  # sale, and a share of another row. Between them they exercise every line the
  # payout breakdown can draw and every control the admin form offers.
  rows = [
    {"Listing fee", %{kind: :flat, amount: 99}, nil},
    {"Commission", %{kind: :percentage, rate_bp: 1000}, nil},
    {"VAT", %{kind: :percentage, rate_bp: 2100}, "Commission"}
  ]

  # Looked up by name rather than kept from the creation above, so a row that
  # was already there is what a later row stacks on.
  by_name = fn ->
    Map.new(Payments.list_seller_deductions!(authorize?: false), &{&1.name, &1})
  end

  for {name, attrs, of} <- rows, not Map.has_key?(by_name.(), name) do
    basis = of && Map.fetch!(by_name.(), of)

    attrs
    |> Map.merge(%{name: name, of_id: basis && basis.id})
    |> Payments.add_seller_deduction!(authorize?: false)
  end
end
