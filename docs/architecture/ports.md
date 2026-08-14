---
type: architecture
title: Ports
description: The Mercato.Ports namespace — behaviour-plus-adapter pattern for the Infra layer's external-service boundaries.
tags: [architecture, ports, adapters, dip, boundary]
timestamp: 2026-08-14T00:00:00Z
---

`Mercato.Ports` is the namespace for the Infra layer's boundary modules (see [architecture.md](architecture.md#-logical-layers)) — the behaviours Core depends on instead of a concrete vendor, per [principles.md → DIP](principles.md#dip--dependency-inversion).

## Structure

Each external-service concern is one `Mercato.Ports.<Concern>` behaviour, with concrete implementations as flat sibling modules named after the provider:

```text
Mercato.Ports.<Concern>            # the behaviour — the contract Core depends on
Mercato.Ports.<Concern>.<Provider> # an implementation, e.g. Local, Stripe, Tigris
```

A concern with more than one distinct responsibility splits into multiple small behaviours rather than one fat one, per [principles.md → ISP](principles.md#isp--interface-segregation) — e.g. a future `Payments` concern would be `Mercato.Ports.Payments.Charging` and `Mercato.Ports.Payments.Payouts`, not a single `Payments` behaviour covering both.

## Wiring

The active implementation is chosen via application config, read with `Application.fetch_env!/2` at the call site — no facade module wraps the lookup:

```elixir
# config/config.exs — default, needs no external service
config :mercato, :storage_adapter, Mercato.Ports.Storage.Local

# a caller
Application.fetch_env!(:mercato, :storage_adapter).put(key, data, opts)
```

An adapter that needs an external provider overrides the config key in `config/runtime.exs`, scoped to the environment that uses it — the default in `config.exs` stays the infra-less option, per the project's rule of thumb (see [AGENTS.md](../../AGENTS.md)).

## Current Ports

| Concern | Behaviour | Default adapter | Config key |
| :--- | :--- | :--- | :--- |
| File storage | `Mercato.Ports.Storage` | `Mercato.Ports.Storage.Local` (local disk) | `:storage_adapter` |

See [docs/guides/index.md](../guides/index.md) for how-to guides on adding a new adapter to an existing port.

## Testing

A port with a single adapter is tested by exercising that adapter directly — no mock needed. Add `Mox` and a `Mox.defmock/2` stub for a port's behaviour only once a second adapter exists and a caller's tests need to swap it out, per [testing.md](testing.md).
