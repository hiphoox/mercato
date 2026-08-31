---
type: explore
title: Promotions Todo
description: Backlog of seller and platform discount campaigns and price-drop promotion.
tags: [promotions, discounts, todo, backlog]
timestamp: 2026-08-31T00:00:00Z
---

Working backlog for discounting and promoting a listing's price. A campaign spans many listings and outlives any one of them, so it is its own entity rather than a listing field — see [listings-todo.md](listings-todo.md) for the per-listing original-price attribute it renders against.

Nothing here is required for the Phase 1 MVP.

## NICE TO HAVE — Phase 2

### Campaigns

- [ ] Seller-level discount campaigns across a seller's own listings
- [ ] Platform-level discount campaigns across the catalog
- [ ] Campaign scheduling with a start and end, and the display treatment while active

### Price drops

- [ ] "Lower price" action on a listing that notifies users who saved it — the buyer-facing half lives in [social-todo.md](social-todo.md)

### Fulfillment promotions

- [ ] Seller absorbing part of the fulfillment cost across chosen listings, as an alternative to discounting the price — see [shipping-todo.md](shipping-todo.md)

## Waiting on

| Area | Why |
| :--- | :--- |
| [listings-todo.md](listings-todo.md) | The original-price attribute a discount renders against, item 46 |
| [social-todo.md](social-todo.md) | A price drop notifies whoever saved the listing; without favorites it notifies nobody |
| Notifications | The whole point of a price drop is that someone hears about it; no area owns notifications yet |
