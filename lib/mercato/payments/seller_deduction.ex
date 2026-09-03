defmodule Mercato.Payments.SellerDeduction do
  @moduledoc """
  One named thing the platform takes off a seller's earnings.

  Commission and tax alike are rows here rather than rules in code: each has a
  name a seller reads on their statement and a value that is either a flat
  amount or a percentage. A percentage names what it is a percentage of — the
  sale price, or another row's amount — so a jurisdiction that taxes the
  commission is one more configured row rather than a change to this file.

  What a marketplace deducts is its own business, so a fresh install deducts
  nothing at all: no rows means a seller keeps the whole sale price.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Payments,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Mercato.Accounts.User.Checks.ActorHasPermission
  alias Mercato.Money
  alias Mercato.Payments
  alias Mercato.Payments.SellerDeduction.Validations

  @editable [:name, :kind, :amount, :rate_bp, :of_id]

  sqlite do
    table "seller_deductions"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]

    read :ordered do
      description "Every deduction, oldest first, which is the order they are applied in."
      # Named as the tiebreak rather than left to the data layer: two rows added
      # in the same instant would otherwise read back in a different order each
      # time, and a statement whose lines move is a statement nobody trusts.
      prepare build(sort: [inserted_at: :asc, name: :asc])
    end

    create :add do
      description "Adds a deduction an operator has configured."
      accept @editable
    end

    update :edit do
      description "Changes what a configured deduction takes, or what it takes it off."
      accept @editable
      # The circularity check reads the other rows, which no atomic update can.
      require_atomic? false
    end

    destroy :remove do
      description "Drops a deduction, so nothing is taken for it from then on."
      require_atomic? false
    end
  end

  policies do
    # Read by everyone: a seller weighs what a sale would leave them before they
    # have made one, and a buyer's checkout is priced off the same rows.
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type([:create, :update, :destroy]) do
      authorize_if {ActorHasPermission, permission: "settings:update"}
    end
  end

  validations do
    # A row says one thing about its value, never two: a flat amount or a rate,
    # and only a rate has something it is a rate of.
    validate present(:amount), where: [attribute_equals(:kind, :flat)]
    validate absent([:rate_bp, :of_id]), where: [attribute_equals(:kind, :flat)]
    validate present(:rate_bp), where: [attribute_equals(:kind, :percentage)]
    validate absent(:amount), where: [attribute_equals(:kind, :percentage)]

    # Only on update: a row being created cannot be named by one that does not
    # exist yet, so a chain can only close on itself once both ends are stored.
    validate Validations.BasisNotCircular, on: [:update]
    validate Validations.NotDependedOn, on: [:destroy]
  end

  attributes do
    uuid_primary_key :id

    # What a seller reads on their statement. Operator configuration rather than
    # copy, so it is shown exactly as it was typed and never translated.
    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :kind, Mercato.Payments.Kind do
      allow_nil? false
      public? true
    end

    # Minor units, like every other amount stored here. Set on a flat row and
    # empty on a percentage one, which the validations above keep true.
    attribute :amount, :integer do
      constraints min: 0
      public? true
    end

    # Basis points — hundredths of a percent — so a rate is integer arithmetic
    # like the amounts it is taken from. 10_000 is the whole of what it is a
    # rate of, and nothing may take more than that.
    attribute :rate_bp, :integer do
      constraints min: 0, max: 10_000
      public? true
    end

    timestamps()
  end

  relationships do
    # What this row is a percentage of. Empty means the sale price itself, which
    # is what an ordinary commission is a percentage of.
    belongs_to :of, __MODULE__ do
      allow_nil? true
      attribute_writable? true
      public? true
    end

    has_many :dependents, __MODULE__ do
      destination_attribute :of_id
      public? true
    end
  end

  identities do
    # A deduction is read by its name, so two rows sharing one would leave a
    # seller unable to tell which of them took what.
    identity :unique_name, [:name]
  end

  @doc """
  What the configured rows take off a sale of `sale_price` minor units.

  Returns each row as a line of its own, in the order the rows are applied, and
  the total they come to. The lines are what a seller is shown; the total is
  what comes off what they are paid.

  Nothing is capped: a marketplace that has configured rows adding up to more
  than the sale is told so by a total larger than the price, rather than by a
  number quietly trimmed to fit.
  """
  def breakdown(sale_price) when is_integer(sale_price) do
    rows = Payments.list_seller_deductions!(authorize?: false)
    amounts = amounts(rows, sale_price)
    lines = Enum.map(rows, &%{name: &1.name, amount: Map.fetch!(amounts, &1.id)})

    %{lines: lines, total: lines |> Enum.map(& &1.amount) |> Enum.sum()}
  end

  defp amounts(rows, sale_price) do
    by_id = Map.new(rows, &{&1.id, &1})

    Enum.reduce(rows, %{}, &resolve(&1, by_id, sale_price, &2))
  end

  # A row that is a percentage of another needs that one's amount first, so the
  # rows are resolved by following what they name rather than by their order.
  # The chain always ends, `BasisNotCircular` having refused one that loops.
  defp resolve(row, by_id, sale_price, amounts) do
    cond do
      Map.has_key?(amounts, row.id) ->
        amounts

      row.kind == :flat ->
        Map.put(amounts, row.id, row.amount)

      is_nil(row.of_id) ->
        Map.put(amounts, row.id, Money.apply_rate(sale_price, row.rate_bp))

      true ->
        amounts = resolve(Map.fetch!(by_id, row.of_id), by_id, sale_price, amounts)
        base = Map.fetch!(amounts, row.of_id)

        Map.put(amounts, row.id, Money.apply_rate(base, row.rate_bp))
    end
  end
end
