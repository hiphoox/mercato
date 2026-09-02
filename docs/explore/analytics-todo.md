---
type: explore
title: Analytics Todo
description: Backlog of seller-facing listing performance metrics.
tags: [analytics, metrics, todo, backlog]
timestamp: 2026-09-01T00:00:00Z
---

Working backlog for measuring how a listing performs. Metrics are recorded as their own event data and read back on demand; a listing carries no counter of its own, which is why this is not part of [listings-todo.md](listings-todo.md).

The storage and query approach is already researched — see [analytics-duckdb.md](analytics-duckdb.md).

Nothing here is required for the Phase 1 MVP.

## NICE TO HAVE — Phase 2

### Seller metrics

- [ ] Per-listing view count and conversion rate, shown to the owning seller
- [ ] View events recorded without a write to the listing itself
- [ ] Seller-level rollup across all of a seller's listings

### Conversion

- [ ] Conversion measured against completed orders rather than views alone — see [orders-todo.md](orders-todo.md)

## Waiting on

| Area | Why |
| :--- | :--- |
| [orders-todo.md](orders-todo.md) | A conversion rate needs something to convert into; view counts alone are traffic, not performance |
| [listings-todo.md](listings-todo.md) | Something whose performance is worth measuring. Already built, so this is satisfied |
