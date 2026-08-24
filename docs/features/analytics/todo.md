---
type: feature
title: Analytics Todo
description: Backlog of seller-facing listing performance metrics.
tags: [analytics, metrics, todo, backlog]
timestamp: 2026-08-24T00:00:00Z
---

Working backlog for measuring how a listing performs. Metrics are recorded as their own event data and read back on demand; a listing carries no counter of its own, which is why this is not part of [listings/todo.md](../listings/todo.md).

The storage and query approach is already researched — see [analytics-duckdb.md](../../explore/analytics-duckdb.md).

Nothing here is required for the Phase 1 MVP.

## NICE TO HAVE — Phase 2

### Seller metrics

- [ ] Per-listing view count and conversion rate, shown to the owning seller
- [ ] View events recorded without a write to the listing itself
- [ ] Seller-level rollup across all of a seller's listings
