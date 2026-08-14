---
type: architecture
title: Background Jobs
description: Background/scheduled job processing baseline and its SQLite constraint.
tags: [architecture, jobs, oban, sqlite]
timestamp: 2026-08-14T00:00:00Z
---

Mercato has no background job library installed yet. When one is added, it is **Oban used directly**, not the `ash_oban` wrapper — a constraint driven by the project's infra-less/SQLite-only rule of thumb (see [data-architecture.md](data-architecture.md)).

## 1. Oban Core Supports SQLite

Oban ships `Oban.Engines.Lite`, a first-class engine for running on SQLite3 via `ecto_sqlite3` — the same adapter `ash_sqlite` already uses in this repo, so it can share `Mercato.Repo`. It supports the same core single-node functionality as the Postgres engine; Postgres remains the better fit only for distributed/high-throughput job processing, which is out of scope for this project's single-instance deployment model.

- Job pickup is polling-based on the Lite engine (no `LISTEN/NOTIFY`), so it is not sub-second — acceptable for this project's background-job use cases.
- Some Oban Web/Pro plugins assume Postgres-specific features; check plugin docs before adding one.

## 2. `ash_oban` Is Not Used

`ash_oban` (the Ash extension that wires resource actions to Oban triggers/scheduled jobs) hard-depends on `postgrex` in its own `mix.exs` — not marked `optional: true`. Installing it pulls in the Postgres driver regardless of the app's actual data layer, which conflicts with the infra-less/SQLite-only baseline.

- Whether `ash_oban`'s runtime logic would actually function against `Oban.Engines.Lite` is unconfirmed by any official source — the hard `postgrex` dependency alone is enough reason to avoid it here.
- If background jobs are needed, add `{:oban, "~> 2.20"}` directly, configure `engine: Oban.Engines.Lite`, point it at `Mercato.Repo`, and call Oban from plain Elixir/Ash code rather than through `ash_oban` triggers.
