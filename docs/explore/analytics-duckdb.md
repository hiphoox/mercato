---
type: explore
title: Analytics via DuckDB
description: Using DuckDB as an embedded analytics engine alongside SQLite, since Ash has no native DuckDB data layer.
tags: [explore, duckdb, analytics, sqlite]
timestamp: 2026-08-14T00:00:00Z
---

Mercato has no analytics engine installed yet. When one is added, it is **DuckDB**, used for analytical queries only — SQLite via `ash_sqlite`/`Mercato.Repo` remains the transactional store for all resources.

## Why DuckDB Fits

DuckDB is embedded (in-process, no server), the same operating model as `exqlite`/SQLite — consistent with the infra-less/SQLite-only rule of thumb (see [data-architecture.md](../architecture/data-architecture.md)). It's a better fit than SQLite for analytical/OLAP workloads (columnar storage, vectorized execution), while SQLite stays the right fit for the transactional/OLTP resource data.

## Ash Has No DuckDB Data Layer

Ash ships official data layers for Postgres and SQLite (`ash_sqlite`, used here), but no `ash_duckdb`. Per Ash's creator, there are two ways to integrate DuckDB with Ash — no official data layer exists for either:

- **Generic actions** — a resource action that takes arguments and returns a value, with no CRUD semantics and no data-layer dispatch at all.
- **Manual actions** (`data_layer: Ash.DataLayer.Simple` + `manual` implementation) — keeps the action's CRUD shape (`create`/`read`/`update`/`destroy`), but the implementation module runs custom code instead of dispatching to a real data layer, handing results back via `Ash.DataLayer.Simple.set_data/2`. `Ash.DataLayer.Simple` is the same data layer embedded resources use under the hood.

**Manual actions are the fit here**: analytics resources still read/query like normal Ash resources (filters, sorting, pagination via the action), while the manual implementation runs the actual DuckDB query underneath. A custom `Ash.DataLayer` behaviour implementation is only worth writing if analytics resources need first-class Ash-level filter/aggregate pushdown into DuckDB itself.

## Elixir Driver

[`duckdbex`](https://duckdbex.hexdocs.pm/readme.html) embeds DuckDB directly (NIF, no external dependency) — `Duckdbex.open/1` + `Duckdbex.connection/1` to connect, `Duckdbex.query/2` + `Duckdbex.fetch_all/1` to run SQL and pull results. This is what a manual action's implementation module calls directly; no Ecto adapter is required for the manual-actions approach.

## Recommendation

Back analytics resources with `data_layer: Ash.DataLayer.Simple` and manual actions whose implementation modules call `duckdbex` directly, converting query results into `Ash.DataLayer.Simple.set_data/2`. Move to a full custom `Ash.DataLayer` only if analytics resources need native Ash filter/aggregate pushdown.

## Reference

- [Using Ash with DuckDB/MotherDuck — Elixir Forum](https://forum.elixirforum.com/t/using-ash-with-duckdb-motherduck-possible-and-or-useful/69098/2) — Ash creator's guidance: no built-in data layer, use generic/manual actions or write a custom one.
- [Manual Actions — Ash docs](https://hexdocs.pm/ash/manual-actions.html)
- [Ash.DataLayer.Simple](https://hexdocs.pm/ash/Ash.DataLayer.Simple.html)
- [duckdbex on HexDocs](https://duckdbex.hexdocs.pm/readme.html) — embedded DuckDB NIF driver.
