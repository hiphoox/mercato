# Fees seeds: sample rows for what the marketplace takes off a seller and what
# it adds to what a buyer pays. Loaded by `priv/repo/seeds.exs`, before the
# listings that copy the seller rows.
#
# Dev only, and deliberately so: a fresh install charges nothing, and a
# deployment decides what it charges from the admin area rather than inheriting
# a rate seeded here. Locally the rows are what make the payout breakdown on the
# sell form, the total breakdown at checkout, and the fee tables in the admin
# area have anything to show.

if Mix.env() == :dev do
  alias Mercato.Payments

  # One row of each shape a deduction may take: a flat amount, a share of the
  # sale, and a share of another row. Between them they exercise every line the
  # payout breakdown can draw and every control the admin form offers.
  deductions = [
    {"Listing fee", %{kind: :flat, amount: 99}, nil},
    {"Commission", %{kind: :percentage, rate_bp: 1000}, nil},
    {"VAT", %{kind: :percentage, rate_bp: 2100}, "Commission"}
  ]

  # A buyer fee is never a share of another fee, so there are only two shapes
  # to seed. Both are drawn as their own line on what a buyer is asked to pay.
  fees = [
    {"Buyer protection", %{kind: :flat, amount: 199}},
    {"Service fee", %{kind: :percentage, rate_bp: 300}}
  ]

  # Looked up by name rather than kept from the creation above, so a row that
  # was already there is what a later row stacks on.
  deductions_by_name = fn ->
    Map.new(Payments.list_seller_deductions!(authorize?: false), &{&1.name, &1})
  end

  for {name, attrs, of} <- deductions, not Map.has_key?(deductions_by_name.(), name) do
    basis = of && Map.fetch!(deductions_by_name.(), of)

    attrs
    |> Map.merge(%{name: name, of_id: basis && basis.id})
    |> Payments.add_seller_deduction!(authorize?: false)
  end

  seeded_fees = MapSet.new(Payments.list_buyer_fees!(authorize?: false), & &1.name)

  for {name, attrs} <- fees, not MapSet.member?(seeded_fees, name) do
    attrs
    |> Map.put(:name, name)
    |> Payments.add_buyer_fee!(authorize?: false)
  end
end
