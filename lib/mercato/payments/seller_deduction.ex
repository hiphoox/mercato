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
  alias Mercato.Payments
  alias Mercato.Payments.Deduction
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
  The configured rows as they stand, in the order they are applied.

  A copy rather than the rows themselves, so whatever is priced against it
  carries the terms it was priced under: see `Mercato.Payments.Deduction`.
  """
  def snapshot do
    rows = Payments.list_seller_deductions!(authorize?: false)
    names = Map.new(rows, &{&1.id, &1.name})

    Enum.map(rows, fn row ->
      Deduction.new!(
        name: row.name,
        kind: row.kind,
        amount: row.amount,
        rate_bp: row.rate_bp,
        of: names[row.of_id]
      )
    end)
  end

  @doc """
  What the configured rows take off a sale of `sale_price` minor units.

  Read against the rows as they stand now, which is what an operator weighing
  a change to them wants. What a listing already on offer owes is read against
  the copy it took, not against this.
  """
  def breakdown(sale_price) when is_integer(sale_price) do
    Deduction.breakdown(snapshot(), sale_price)
  end
end
