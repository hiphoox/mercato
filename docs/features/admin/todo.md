---
type: feature
title: Admin Todo
description: Backlog of admin capabilities for running the platform, starting with content moderation.
tags: [admin, moderation, todo, backlog]
timestamp: 2026-08-24T00:00:00Z
---

Working backlog for admin-only capabilities. Account administration has its own backlog in [users/todo.md](../users/todo.md); this file covers moderation of content sellers and buyers create.

Nothing here is required for the Phase 1 MVP. The listing side of a moderation delete is already built — taking a listing down, keeping it and its images as a backup, and a moderation-only view of what has been taken down — so several items below are an admin screen over behaviour that already exists rather than new behaviour. See [data-architecture.md](../../architecture/data-architecture.md) for the soft-delete rules and [listings/todo.md](../listings/todo.md) for what landed.

## NICE TO HAVE — Phase 2

### Moderation queue

- [ ] Buyer report action on a listing, feeding an admin moderation queue
- [ ] Queue triage: dismiss a report, or moderate the reported listing
- [ ] Admin trigger for taking a listing down — the soft delete itself, distinct from a seller's own delete, is already built and gated on the `listing:delete` permission
- [ ] Moderation view of listings that have been taken down, which is the only place the retained backup can be seen
- [ ] Restore a listing taken down in error, putting it back in the state it was in — without this a moderation delete is irreversible in practice, which is the one thing keeping the record was meant to avoid
- [ ] Automated moderation pattern matching on new listings, routing a match to the same queue

### Marketplace settings

The platform already holds a single admin-configurable settings record; the values a marketplace tunes are still spread across config files and only change on redeploy.

- [ ] Move the tunable values into that settings record so an operator edits them rather than a deployer: currency, the listing condition list, allowed image types, the image size cap, the image count bounds, and the listing field bounds in [listings/todo.md](../listings/todo.md)
- [ ] Settings screen in the admin dashboard for editing them, with the platform defaults still applying wherever nothing has been set
