---
type: architecture
title: Architecture
description: Architecture baselines.
tags: [architecture, layers, dependency-flow]
timestamp: 2026-08-13T00:00:00Z
---

The technical blueprint for Mercato — a general-purpose C2C marketplace platform built on Phoenix and the Ash Framework. This file covers the system's shape; deeper concerns live in sibling docs (see [Related](#related)).

## 🏗 Logical Layers

The system is organized into logical layers to ensure a strict separation of concerns and a one-way flow of dependencies.

| Layer     | Responsibility | Description                                                                                                                                                         |
| :-------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Web**   | Entry Point    | Handles HTTP requests, Phoenix LiveView state, and the REST/JSON API for mobile clients. Uses Ash Phoenix for CRUD.                                                 |
| **Core**  | Logic Engine   | The heart of the system. Defined as a set of **Ash Domains and Resources**. All business rules, validations, and orchestration reside here.                         |
| **Data**  | Data Layer     | A single **SQLite** database file, accessed through Ash/Ecto via `AshSqlite`. Holds all marketplace data — users, listings, transactions, payouts, and more. `AshSqlite` doesn't support Ash aggregates; compute equivalent values in queries or resource calculations instead.  |
| **Infra** | Utility Layer  | Low-level wrappers for external services (payments, messaging, shipping, address lookup). Implements the Boundary Pattern to decouple the core from 3rd-party APIs. |

## Dependency Flow

Dependencies point in one direction only: a layer may call **downward** (into layers below it), and **nothing ever calls back up**. This is what prevents circular dependencies.

It is _not_ a linear pipeline — in Ash + Phoenix, **Core** orchestrates _both_ **Data** and **Infra** (Data does not depend on Infra):

```text
Web   (LiveView · controllers · JSON API)
 └─▶ Core   (Ash Domains + Resources — business rules & orchestration)
      ├─▶ Data    (AshSqlite → SQLite)
      └─▶ Infra   (external-service boundaries: payments, messaging, shipping)
```

Core depends on the Infra **behaviours**, never the concrete vendors — Dependency Inversion in practice (see [principles.md → DIP](principles.md#dip--dependency-inversion)). A Stripe webhook or shipping callback does not violate this: it re-enters through **Web**, then flows down again.

## Related

- [principles.md](principles.md) — SOLID applied to Elixir/Ash, with code examples.
- [data-architecture.md](data-architecture.md) — SQLite, AshSqlite, migrations, soft-delete, backups.
- [security.md](security.md) — Authentication and authorization model.
- [index.md](index.md) — Map of all architecture docs.
