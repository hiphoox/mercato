---
type: explore
title: Social Todo
description: Backlog of social interactions on listings — favorites and public comments.
tags: [social, favorites, comments, todo, backlog]
timestamp: 2026-08-31T00:00:00Z
---

Working backlog for social interaction around a listing. Each capability here introduces its own entity that *points at* a listing rather than changing one, which is why it is not part of [listings-todo.md](listings-todo.md).

Nothing in this area is required for the Phase 1 MVP — a buyer can find and buy a listing without any of it. The whole file is Phase 2.

Reputation earned by trading is not social interaction and lives in [reviews-todo.md](reviews-todo.md): a comment is what anyone may say about a listing, a review is what a counterparty may say about a finished order.

## NICE TO HAVE — Phase 2

### Favorites

- [ ] Save/favorite a listing, with a public favorite count on the card
- [ ] A saved-listings view on the buyer's own account
- [ ] Notify users who saved a listing when its price drops — the seller-facing half of this lives in [promotions-todo.md](promotions-todo.md)

### Comments

- [ ] Public comments on a listing
- [ ] Comment visibility gated by account status; a `restricted` account cannot comment — see [users-todo.md](users-todo.md)
- [ ] Reporting a comment feeds the same moderation queue as a reported listing — see [admin-todo.md](admin-todo.md)

### Following

- [ ] Follow a seller, with the follow visible to both parties
- [ ] A view of recent listings from the sellers a buyer follows
- [ ] Following as a signal into discovery ranking — see [discovery-todo.md](discovery-todo.md)

## Unowned dependencies

Two capabilities this area needs have no backlog of their own yet:

- **Private messaging** — a buyer asking a seller a question before buying. Distinct from public comments, and needed by [disputes-todo.md](disputes-todo.md) for pre-operator negotiation.
- **Notifications** — a favorite's price drop, a new comment, a new follower. Referenced here and in [promotions-todo.md](promotions-todo.md), owned by neither.
