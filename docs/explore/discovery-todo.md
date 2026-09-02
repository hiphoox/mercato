---
type: explore
title: Discovery Todo
description: Backlog of browse, search, filter, and ranking capabilities, split into Phase 1 MVP musts and Phase 2 nice-to-haves.
tags: [discovery, search, todo, backlog, mvp]
timestamp: 2026-09-01T00:00:00Z
---

Working backlog for how a buyer finds a listing — browsing, searching, filtering, and ranking. The `Listing` entity itself is a separate concern; its fields, lifecycle, and authoring live in [listings-todo.md](listings-todo.md).

The Phase 1 MVP is "list an item, find it, buy it". _Find it_ is this file; _list it_ is the listings backlog. Neither area's Phase 1 is shippable alone.

Flows referenced here are already specified in [commerce-ux-patterns.md](../architecture/commerce-ux-patterns.md); this file tracks what to build, not how it should behave on screen.

- **MUST** — Phase 1 MVP: enough for a buyer to find a listing that exists.
- **NICE TO HAVE** — Phase 2: depth, personalization, and a pluggable search engine.

## MUST — Phase 1 MVP

### Browse & search

- [x] Public browse grid of `active` listings, newest first
- [x] Keyword search over title and description
- [x] Type-ahead suggestions over titles, categories and seller handles
- [x] Sort by newest and by price ascending/descending, from a declared set an instance can replace — see [discovery-facets.md](../architecture/discovery-facets.md)
- [x] Pagination or infinite scroll on the grid

### Filtering

- [x] Filter by category, from the header's scope selector
- [x] Filter by price range, plus condition where a condition list is configured
- [x] Only `active` listings appear in browse and search results

## NICE TO HAVE — Phase 2

### How the filter set and the search engine divide

The customizable filter set and the search port are separate on purpose, and building them in that order is what keeps the second one a small change. The filter set is built; the search port is not.

**The filter set is a product decision.** Which facets a marketplace offers, what each is labelled, and which values it lists come from the instance's own configuration: a car marketplace offers mileage and year, a clothes marketplace offers size and brand. A declared facet names the field it narrows, the kind of narrowing it does (one value from a list, a numeric range), and where it draws on the bar. One declaration feeds both the query and the controls, so adding a facet is one entry rather than an edit to the read, the bar, the sheet, the chips, and the address.

**The search engine is an execution decision.** It owns what the facet set deliberately does not:

- **Relevance.** A term is matched and _ranked_, with stemming and typo tolerance, rather than scanned for as a substring in whatever order rows come back.
- **Where narrowing runs.** The same declared facets execute as local query clauses on the default adapter, or in an external engine's own filter syntax on an opt-in one.
- **Facet counts.** Counting every option of every facet is a query apiece locally and a free field in an external engine, so whether counts come back is a capability an adapter states.
- **Swappability.** The default needs no service beyond the app; an instance with a large catalogue swaps in an external engine by configuration, without touching the browse page or the filter set.

Swapping engines never changes which filters a buyer sees. A declared facet an adapter cannot execute is a startup failure rather than a request-time one.

The free-text term stays outside the facet set for this reason: it is the engine's concern, where a facet is the operator's.

### Search engine

- [ ] Search port with a SQLite FTS5 default adapter and an external engine as an opt-in adapter — see [full-text-search.md](full-text-search.md)
- [ ] Saved searches with new-match alerts
- [ ] Facet result counts on every filter option

### Filtering depth

- [x] Customizable filter set — declared facets driving both the query and the controls; the rules now live in [discovery-facets.md](../architecture/discovery-facets.md) and the procedure in [browse-filters.md](../guides/browse-filters.md)
- [x] Customizable sort set — declared orders, each naming its own columns and inheriting the tie-break from the default
- [ ] Location-based filtering and local pickup
- [ ] Sold-only filter with sold listings ranked last in general results
- [ ] Filtering on category-scoped attributes, once listings carry them

### Ranking & recommendation

- [ ] Personalized ranking on home and explore
- [ ] Similar listings and more-from-this-seller carousels
- [ ] Recently viewed listings
- [ ] Curated collections placed into home and explore sections
- [ ] Rule-based collections that fill and empty themselves as listings match or stop matching, defined over the same declared facets the filter bar uses, so an operator composes one without a deploy

### Pricing intelligence

- [ ] Suggested-price hint from comparable sold listings, surfaced to a seller at authoring time

## Waiting on

| Area | Why |
| :--- | :--- |
| [listings-todo.md](listings-todo.md) | Something to browse and search. Already built, so this is satisfied |
| [admin-todo.md](admin-todo.md) | The declared browse filters become operator-editable there, in Phase 2 |

## Depended on by

| Area | Why |
| :--- | :--- |
| [social-todo.md](social-todo.md) | Following as a signal into ranking |
| [reviews-todo.md](reviews-todo.md) | Reputation as a signal into ranking |
| [admin-todo.md](admin-todo.md) | The declared filters to make editable |
