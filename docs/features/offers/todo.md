---
type: feature
title: Offers Todo
description: Backlog of buyer offer and seller counter-offer negotiation on a listing.
tags: [offers, negotiation, todo, backlog]
timestamp: 2026-08-24T00:00:00Z
---

Working backlog for price negotiation on a listing. An offer is its own entity with its own lifecycle, expiry, and authorization rules — the listing it references is left unchanged until an offer is accepted, which is why this is not part of [listings/todo.md](../listings/todo.md).

The negotiation UX is already specified in [commerce-ux-patterns.md](../../architecture/commerce-ux-patterns.md).

Nothing here is required for the Phase 1 MVP; a buyer buys at the asking price.

## NICE TO HAVE — Phase 2

### Negotiation

- [ ] Buyer makes an offer on a listing below the asking price
- [ ] Seller accepts, declines, or counters
- [ ] Offer states and their terminal transitions, including expiry
- [ ] Accepting an offer is what starts checkout, at the agreed price
- [ ] A listing reaching `sold` resolves every open offer against it
- [ ] Seller can disable offers per listing, and the instance can disable them entirely by config
