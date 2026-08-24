---
type: feature
title: Admin Todo
description: Backlog of admin capabilities for running the platform, starting with content moderation.
tags: [admin, moderation, todo, backlog]
timestamp: 2026-08-24T00:00:00Z
---

Working backlog for admin-only capabilities. Account administration has its own backlog in [users/todo.md](../users/todo.md); this file covers moderation of content sellers and buyers create.

Nothing here is required for the Phase 1 MVP, though the soft-delete behaviour a moderation delete relies on is already specified — see [data-architecture.md](../../architecture/data-architecture.md).

## NICE TO HAVE — Phase 2

### Moderation queue

- [ ] Buyer report action on a listing, feeding an admin moderation queue
- [ ] Queue triage: dismiss a report, or moderate the reported listing
- [ ] Moderation delete is a soft delete keeping an internal backup, distinct from a seller's own delete — see [listings/todo.md](../listings/todo.md)
- [ ] Automated moderation pattern matching on new listings, routing a match to the same queue

### Marketplace settings

The platform already holds a single admin-configurable settings record; the values a marketplace tunes are still spread across config files and only change on redeploy.

- [ ] Move the tunable values into that settings record so an operator edits them rather than a deployer: currency, the listing condition list, allowed image types, the image size cap, the image count bounds, and the listing field bounds in [listings/todo.md](../listings/todo.md)
- [ ] Settings screen in the admin dashboard for editing them, with the platform defaults still applying wherever nothing has been set
