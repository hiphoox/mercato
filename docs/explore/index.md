---
type: index
title: Explore Docs
description: Map of docs/explore/ — research, decisions, and per-area backlogs for capabilities not yet implemented.
tags: [explore, index, todo, backlog]
timestamp: 2026-09-01T00:00:00Z
---

Map of `docs/explore/`. This section holds everything the project doesn't have yet: research findings, decisions taken ahead of implementation, and the backlogs tracking what is left to build. Once a capability is actually built, the rules governing it move to the section that owns it (usually `architecture/` or `domain/`) and are reconciled against the real code.

**Before researching or designing a solution for something that doesn't exist in the codebase yet, check here first** — the exploration may already be done.

## Research & decisions

- [analytics-duckdb.md](analytics-duckdb.md) — Analytics via embedded DuckDB (`duckdbex`), backed by Ash manual actions since there's no `ash_duckdb`. Read it before designing metrics storage or queries.
- [background-jobs.md](background-jobs.md) — Background/scheduled job processing baseline (Oban core, not `ash_oban`) and its SQLite constraint. Read it before adding anything that runs off the request cycle.
- [full-text-search.md](full-text-search.md) — Full-text search via SQLite FTS5: virtual table migration, schema, and query pattern. Read it before building search.

## Backlogs

One file per area, each split into **MUST** (Phase 1 MVP) and **NICE TO HAVE** (Phase 2). Read the one for your area before picking up work, to check whether a capability is already built or still planned.

**The purchase, and what it needs**

- [orders-todo.md](orders-todo.md) — Buying a listing: the order record, the cart, checkout, fulfillment states, and seeing a purchase through.
- [payments-todo.md](payments-todo.md) — The money: charging a buyer, holding it in escrow, commission, and paying a seller out.
- [shipping-todo.md](shipping-todo.md) — Getting a bought listing to its buyer, and the fulfillment methods an instance configures.
- [disputes-todo.md](disputes-todo.md) — What happens when a buyer is unhappy, and who decides the fate of held funds.

**The catalog, and finding it**

- [listings-todo.md](listings-todo.md) — The `Listing` entity a seller publishes and a buyer buys: fields, media, lifecycle, authoring.
- [discovery-todo.md](discovery-todo.md) — How a buyer finds a listing: browsing, searching, filtering, ranking.
- [promotions-todo.md](promotions-todo.md) — Discount campaigns and price-drop promotion.
- [offers-todo.md](offers-todo.md) — Price negotiation: buyer offers and seller counter-offers.

**The people**

- [users-todo.md](users-todo.md) — User accounts: signup, login, roles, permissions, account lifecycle.
- [reviews-todo.md](reviews-todo.md) — The reputation two parties build by trading with each other.
- [social-todo.md](social-todo.md) — Social interaction on a listing: favorites, public comments, and following.

**Running the platform**

- [admin-todo.md](admin-todo.md) — Admin-only capabilities: moderation, the dispute queue, and operator-editable platform settings.
- [analytics-todo.md](analytics-todo.md) — Seller-facing listing performance metrics.

## Phase 1

The Phase 1 MVP is "list an item, find it, buy it" — spanning `listings`, `discovery`, and `orders`. No area's Phase 1 is shippable alone.

*List it* and *find it* are built. *Buy it* is not, and it is the only Phase 1 work left: `orders` carries the record and the flow, and it cannot complete without the escrow hold in `payments`. `shipping` has a Phase 1 too, but its default is deliberately a manual one needing no carrier.

## Areas nothing owns yet

Two capabilities are referenced across several backlogs and have no file of their own. Both are worth their own area before whichever feature needs them first is built:

- **Notifications** — every area above ends up needing to tell a person something happened. Channels, categories, what a user may switch off, and what they may not.
- **Private messaging** — a buyer asking a seller a question, and the pre-operator negotiation in [disputes-todo.md](disputes-todo.md).
