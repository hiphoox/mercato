---
type: architecture
title: Principles
description: SOLID applied to Elixir/Ash, with code examples.
tags: [architecture, solid, principles]
timestamp: 2026-08-13T00:00:00Z
---

The system follows **SOLID**, adapted to Elixir/Ash. There is no class inheritance here, so the mechanisms are **behaviours**, **Ash actions/extensions**, and **config-injected dependencies** rather than subclassing. See [architecture.md](architecture.md) for the layers these principles apply to.

The examples below build incrementally on one resource, `Mercato.Transactions.Transaction`.

## SRP — Single Responsibility

Each module has one reason to change. This maps onto the layers, and finer-grained onto **one Ash resource per entity** and **one action per operation** (specific verbs, never a catch-all `:update`). The operation is **specified on the resource action**; the domain **code interface only exposes it** — no business logic lives on the interface.

```elixir
# RESOURCE — the specification. One action = one operation.
defmodule Mercato.Transactions.Transaction do
  use Ash.Resource, domain: Mercato.Transactions, data_layer: AshSqlite.DataLayer

  actions do
    update :checkout do        # not a generic :update
      argument :payment_method_id, :string, allow_nil?: false
      change Mercato.Transactions.Changes.ChargePayment
    end

    update :cancel do
      change set_attribute(:status, :cancelled)
    end
  end
end

# DOMAIN — the code interface only exposes actions; no rules live here.
defmodule Mercato.Transactions do
  use Ash.Domain

  resources do
    resource Mercato.Transactions.Transaction do
      define :checkout, action: :checkout   # → Mercato.Transactions.checkout/2
      define :cancel, action: :cancel
    end
  end
end
```

## OCP — Open/Closed

Behavior is extended by **adding** actions, changes, or Ash extensions to the resource above — not by editing existing code. Ash's own features (AshJsonApi, AshAuthentication) plug in exactly this way.

```elixir
use Ash.Resource,
  domain: Mercato.Transactions,
  data_layer: AshSqlite.DataLayer,
  extensions: [AshJsonApi.Resource]   # add capabilities without touching existing actions

actions do
  # ...:checkout and :cancel stay untouched...
  update :apply_discount do
    change Mercato.Transactions.Changes.ApplyDiscount
  end
end
```

This is also how the platform stays a generic starter kit: resources ship with the minimal field/action set a use case needs, and marketplace-specific needs are layered on as new attributes/actions rather than baked into the original resource. `Mercato.Accounts.User` starts minimal — auth needs `email` and `hashed_password`, checkout needs a `display_name` — and a later feature (e.g. seller ratings) adds an attribute and a relationship, never a rewrite of the resource:

```elixir
defmodule Mercato.Accounts.User do
  use Ash.Resource, domain: Mercato.Accounts, data_layer: AshSqlite.DataLayer

  attributes do
    attribute :email, :ci_string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false
    attribute :display_name, :string, allow_nil?: false
    # seller_rating, shipping_preference, etc. get added here only once a
    # feature actually needs them — not speculatively.
  end
end
```

## LSP — Liskov Substitution

Any implementation of a behaviour must be swappable without the caller noticing — same return contract, same semantics. Ash relies on this too (any `Ash.DataLayer` is interchangeable).

```elixir
defmodule Mercato.Payments.Gateway do
  @callback charge(map()) :: {:ok, map()} | {:error, term()}
end

# Both honor the exact contract; Core cannot tell them apart.
defmodule Mercato.Payments.Stripe do
  @behaviour Mercato.Payments.Gateway
  def charge(params), do: # ... real Stripe call
end

defmodule Mercato.Payments.Mock do
  @behaviour Mercato.Payments.Gateway
  def charge(_params), do: {:ok, %{id: "ch_test"}}   # tests / sandbox
end
```

## ISP — Interface Segregation

Prefer small, focused behaviours and expose **specific** domain code interfaces — clients depend only on what they use. Charging and payouts are separate concerns, so they are separate contracts; `Mercato.Transactions` above already only exposes `:checkout` and `:cancel`, never a fat CRUD surface.

```elixir
defmodule Mercato.Payments.Charging do
  @callback charge(map()) :: {:ok, map()} | {:error, term()}
  @callback refund(String.t()) :: {:ok, map()} | {:error, term()}
end

defmodule Mercato.Payments.Payouts do
  @callback transfer(map()) :: {:ok, map()} | {:error, term()}   # Stripe Connect — separate concern
end
```

## DIP — Dependency Inversion

Core depends on the **abstraction** (`Mercato.Payments.Gateway`, from LSP above), never on the concrete vendor. The implementation is injected via config — which is what makes Infra a swappable leaf.

```elixir
# config/runtime.exs
config :mercato, :payment_gateway, Mercato.Payments.Stripe

# ChargePayment change (used by :checkout above) calls the abstraction it is given.
defmodule Mercato.Transactions.Changes.ChargePayment do
  use Ash.Resource.Change

  def change(changeset, _opts, _ctx) do
    gateway = Application.fetch_env!(:mercato, :payment_gateway)

    Ash.Changeset.after_action(changeset, fn _changeset, tx ->
      case gateway.charge(%{amount: tx.total, currency: tx.currency}) do
        {:ok, charge}    -> {:ok, %{tx | status: :paid, stripe_charge_id: charge.id}}
        {:error, reason} -> {:error, reason}
      end
    end)
  end
end
```
