defmodule Mercato.Payments.BuyerFee do
  @moduledoc """
  One named thing the platform adds to what a buyer pays.

  A protection fee and anything like it are rows here rather than rules in
  code: each has a name a buyer reads at checkout and a value that is either a
  flat amount or a percentage of the sale price. Unlike what is deducted from a
  seller, a fee is never a percentage of another fee — a buyer is told what they
  are paying on top of the price, not a stack of charges on charges.

  A marketplace charging its buyers nothing configures no rows, which is what a
  fresh install does.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Payments,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Mercato.Accounts.User.Checks.ActorHasPermission
  alias Mercato.Money
  alias Mercato.Payments

  @editable [:name, :kind, :amount, :rate_bp]

  sqlite do
    table "buyer_fees"
    repo Mercato.Repo
  end

  actions do
    defaults [:read]

    read :ordered do
      description "Every fee, oldest first, which is the order they are shown in."
      prepare build(sort: [inserted_at: :asc, name: :asc])
    end

    create :add do
      description "Adds a fee an operator has configured."
      accept @editable
    end

    update :edit do
      description "Changes what a configured fee adds."
      accept @editable
    end

    destroy :remove do
      description "Drops a fee, so nothing is added for it from then on."
    end
  end

  policies do
    # Read by everyone, signed in or not: what a purchase comes to is shown
    # before anybody has an account to be authorized as.
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type([:create, :update, :destroy]) do
      authorize_if {ActorHasPermission, permission: "settings:update"}
    end
  end

  validations do
    validate present(:amount), where: [attribute_equals(:kind, :flat)]
    validate absent(:rate_bp), where: [attribute_equals(:kind, :flat)]
    validate present(:rate_bp), where: [attribute_equals(:kind, :percentage)]
    validate absent(:amount), where: [attribute_equals(:kind, :percentage)]
  end

  attributes do
    uuid_primary_key :id

    # Operator configuration rather than copy, so it is shown exactly as it was
    # typed and never translated.
    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :kind, Mercato.Payments.Kind do
      allow_nil? false
      public? true
    end

    attribute :amount, :integer do
      constraints min: 0
      public? true
    end

    # Basis points of the sale price. 10_000 is the whole of it.
    attribute :rate_bp, :integer do
      constraints min: 0, max: 10_000
      public? true
    end

    timestamps()
  end

  identities do
    identity :unique_name, [:name]
  end

  @doc """
  What the configured rows add to a sale of `sale_price` minor units.

  Returns each row as a line of its own, in the order they are shown, and the
  total they come to. The buyer pays the price plus that total.
  """
  def breakdown(sale_price) when is_integer(sale_price) do
    lines =
      Payments.list_buyer_fees!(authorize?: false)
      |> Enum.map(&%{name: &1.name, amount: amount(&1, sale_price)})

    %{lines: lines, total: lines |> Enum.map(& &1.amount) |> Enum.sum()}
  end

  defp amount(%__MODULE__{kind: :flat, amount: amount}, _sale_price), do: amount

  defp amount(%__MODULE__{kind: :percentage, rate_bp: rate}, sale_price),
    do: Money.apply_rate(sale_price, rate)
end
