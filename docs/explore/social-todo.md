---
type: explore
title: Social Todo
description: Backlog of social interactions on listings — favorites and public comments.
tags: [social, favorites, comments, todo, backlog]
timestamp: 2026-08-24T00:00:00Z
---

Working backlog for social interaction around a listing. Each capability here introduces its own entity that *points at* a listing rather than changing one, which is why it is not part of [listings-todo.md](listings-todo.md).

Nothing in this area is required for the Phase 1 MVP — a buyer can find and buy a listing without any of it. The whole file is Phase 2.

## NICE TO HAVE — Phase 2

### Favorites

- [ ] Save/favorite a listing, with a public favorite count on the card
- [ ] A saved-listings view on the buyer's own account
- [ ] Notify users who saved a listing when its price drops — the seller-facing half of this lives in [promotions-todo.md](promotions-todo.md)

### Comments

- [ ] Public comments on a listing
- [ ] Comment visibility gated by account status; a `restricted` account cannot comment — see [users-todo.md](users-todo.md)
- [ ] Reporting a comment feeds the same moderation queue as a reported listing — see [admin-todo.md](admin-todo.md)
