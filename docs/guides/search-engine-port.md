---
type: guide
title: Search Engine Port
description: How a search engine will be added behind a port, and what is already settled about the boundary.
tags: [guide, discovery, search, ports, adapters, work-in-progress]
timestamp: 2026-08-31T00:00:00Z
---

> **Work in progress.** The search port does not exist yet. The division of labour below is settled and the filter half of it is built; the behaviour's callbacks, the query and result shapes, and the FTS5 adapter are not. Treat the code in this guide as illustrative, not as an interface to implement against. The backlog entry is in [discovery-todo.md](../explore/discovery-todo.md) and the FTS5 research is in [full-text-search.md](../explore/full-text-search.md).

Free-text search currently runs as a case-insensitive substring match over a listing's title and description, applied directly by the browse read. It has no ranking, no stemming and no typo tolerance. The port is where that changes, and where an external engine becomes an option for an instance whose catalogue has outgrown a substring scan.

## What the port owns, and what it does not

The split matters more than the interface, and it is the reason the filter set was built first.

**The filter set is a product decision.** Which facets a marketplace offers, what they are called, and which values they list is the operator's choice, declared in configuration — see [browse-filters.md](browse-filters.md). It does not change when the engine changes.

**The engine is an execution decision.** It owns:

- **Relevance** — matching and ranking a term, rather than scanning for it as a substring.
- **Where narrowing runs** — the same declared facets execute as local query clauses on the default adapter, or in an external engine's own filter syntax on an opt-in one.
- **Facet counts** — counting every option of every facet is a query apiece locally and a free field in an external engine, so whether counts come back is a capability an adapter states rather than something every adapter must provide.
- **Swappability** — the default needs no service beyond the app, per the infra-less rule of thumb in [AGENTS.md](../../AGENTS.md).

Two invariants follow, and any implementation has to keep them:

- Swapping engines never changes which filters a buyer sees.
- A declared facet an adapter cannot execute is a startup failure, not a request-time one.

## Where it will live

`Mercato.Ports.Search`, following the behaviour-plus-adapter pattern every boundary here uses — see [ports.md](../architecture/ports.md). The default adapter uses SQLite's FTS5, which needs no extra service; an external engine is a sibling module selected by one config key.

```elixir
# config/config.exs — the default, needing no external service
config :mercato, :search_adapter, Mercato.Ports.Search.Fts5
```

An adapter needing an external provider overrides that key in `config/runtime.exs`, scoped to the environment that uses it, leaving the infra-less option as the default.

## Steps, once the behaviour exists

1. Implement the behaviour in `Mercato.Ports.Search.<Provider>`.
2. Declare which facet kinds the adapter can execute, and whether it returns facet counts.
3. Add whatever the provider needs — an index, a sync job, credentials as runtime secrets.
4. Point `:search_adapter` at the module in the environment that should use it.
5. Exercise the adapter's own tests. A port with one adapter is tested by exercising it directly; a mock is added only once a second adapter exists and a caller's tests need to swap it — see [testing.md](../architecture/testing.md).

## Open questions

- The query and result shapes, including how facet counts are returned by an adapter that has them and absent from one that does not.
- How an external engine's index is kept current on a data layer with no transactions.
- Whether relevance joins the sort orders the bar offers, which it can only do once there is a ranking to sort by.
