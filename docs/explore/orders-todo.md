---
type: explore
title: Orders Todo
description: Backlog of the purchase a buyer makes on a listing and the order record it creates.
tags: [orders, purchase, checkout, escrow, todo, backlog]
timestamp: 2026-08-24T00:00:00Z
---

Working backlog for buying a listing. An order is its own entity with its own lifecycle, payment state, and authorization rules, so a capability belongs here rather than in [listings-todo.md](listings-todo.md) whenever it is the order that governs it.

The Phase 1 MVP is "list an item, find it, buy it" — *buy it* is this file, *list it* is the listings backlog, and *find it* is [discovery-todo.md](discovery-todo.md). None of the three is shippable alone.

The purchase and escrow flow is not designed yet; this file holds only what other areas have already found they need from it. The payment provider integration is an adapter behind a port — see [ports.md](../architecture/ports.md).

## MUST — Phase 1 MVP

### Effect on a listing

1. [ ] A purchase completing moves its listing to `sold` — the listing side of this already exists and is waiting to be called
2. [ ] Deleting a listing with a purchase in flight is refused or requires explicit confirmation — moved from [listings-todo.md](listings-todo.md), where it could not be built without an order to be in flight

### Fulfillment

3. [ ] Publish blocked until the seller satisfies the configured fulfillment prerequisites; the shipped-goods default requires a shipping-origin address, and a marketplace of services or digital goods configures none — moved from [listings-todo.md](listings-todo.md), where the rule lives on publish but the prerequisites do not exist to check. The seller address it needs is [users-todo.md](users-todo.md) item 42
