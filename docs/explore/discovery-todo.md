---
type: explore
title: Discovery Todo
description: Backlog of browse, search, filter, and ranking capabilities, split into Phase 1 MVP musts and Phase 2 nice-to-haves.
tags: [discovery, search, todo, backlog, mvp]
timestamp: 2026-08-24T00:00:00Z
---

Working backlog for how a buyer finds a listing — browsing, searching, filtering, and ranking. The `Listing` entity itself is a separate concern; its fields, lifecycle, and authoring live in [listings-todo.md](listings-todo.md).

The Phase 1 MVP is "list an item, find it, buy it". *Find it* is this file; *list it* is the listings backlog. Neither area's Phase 1 is shippable alone.

Flows referenced here are already specified in [commerce-ux-patterns.md](../architecture/commerce-ux-patterns.md); this file tracks what to build, not how it should behave on screen.

- **MUST** — Phase 1 MVP: enough for a buyer to find a listing that exists.
- **NICE TO HAVE** — Phase 2: depth, personalization, and a pluggable search engine.

## MUST — Phase 1 MVP

### Browse & search

- [x] Public browse grid of `active` listings, newest first
- [ ] Keyword search over title and description
- [ ] Sort by newest and by price ascending/descending
- [ ] Pagination or infinite scroll on the grid

### Filtering

- [ ] Filter by category and price range, plus condition where a condition list is configured
- [ ] Only `active` listings appear in browse and search results

## NICE TO HAVE — Phase 2

### Search engine

- [ ] Search port with a SQLite FTS5 default adapter and an external engine as an opt-in adapter — see [full-text-search.md](full-text-search.md)
- [ ] Saved searches with new-match alerts
- [ ] Facet result counts on every filter option

### Filtering depth

- [ ] Location-based filtering and local pickup
- [ ] Sold-only filter with sold listings ranked last in general results
- [ ] Filtering on category-scoped attributes, once listings carry them

### Ranking & recommendation

- [ ] Personalized ranking on home and explore
- [ ] Similar listings and more-from-this-seller carousels
- [ ] Recently viewed listings
- [ ] Curated collections placed into home and explore sections

### Pricing intelligence

- [ ] Suggested-price hint from comparable sold listings, surfaced to a seller at authoring time
