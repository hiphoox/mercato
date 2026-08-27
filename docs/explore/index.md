---
type: index
title: Explore Docs
description: Map of docs/explore/ — research, decisions, and per-area backlogs for capabilities not yet implemented.
tags: [explore, index, todo, backlog]
timestamp: 2026-08-27T00:00:00Z
---

Map of `docs/explore/`. This section holds everything the project doesn't have yet: research findings, decisions taken ahead of implementation, and the backlogs tracking what is left to build. Once a capability is actually built, the rules governing it move to the section that owns it (usually `architecture/` or `domain/`) and are reconciled against the real code.

**Before researching or designing a solution for something that doesn't exist in the codebase yet, check here first** — the exploration may already be done.

## Research & decisions

- [analytics-duckdb.md](analytics-duckdb.md) — Analytics via embedded DuckDB (`duckdbex`), backed by Ash manual actions since there's no `ash_duckdb`. Read it before designing metrics storage or queries.
- [background-jobs.md](background-jobs.md) — Background/scheduled job processing baseline (Oban core, not `ash_oban`) and its SQLite constraint. Read it before adding anything that runs off the request cycle.
- [full-text-search.md](full-text-search.md) — Full-text search via SQLite FTS5: virtual table migration, schema, and query pattern. Read it before building search.

## Backlogs

One file per area, each split into **MUST** (Phase 1 MVP) and **NICE TO HAVE** (Phase 2). Read the one for your area before picking up work, to check whether a capability is already built or still planned.

- [listings-todo.md](listings-todo.md) — The `Listing` entity a seller publishes and a buyer buys: fields, media, lifecycle, authoring.
- [discovery-todo.md](discovery-todo.md) — How a buyer finds a listing: browsing, searching, filtering, ranking.
- [orders-todo.md](orders-todo.md) — Buying a listing: the order record, escrow, delivery confirmation, payout.
- [offers-todo.md](offers-todo.md) — Price negotiation: buyer offers and seller counter-offers.
- [social-todo.md](social-todo.md) — Social interaction on a listing: favorites and public comments.
- [promotions-todo.md](promotions-todo.md) — Discount campaigns and price-drop promotion.
- [analytics-todo.md](analytics-todo.md) — Seller-facing listing performance metrics.
- [users-todo.md](users-todo.md) — User accounts: signup, login, roles, permissions, account lifecycle.
- [admin-todo.md](admin-todo.md) — Admin-only capabilities: content moderation and operator-editable platform settings.

The Phase 1 MVP is "list an item, find it, buy it" — spanning `listings`, `discovery`, and `orders`. No area's Phase 1 is shippable alone.
