---
type: explore
title: Admin Todo
description: Backlog of admin capabilities for running the platform, starting with content moderation.
tags: [admin, moderation, todo, backlog]
timestamp: 2026-09-03T00:00:00Z
---

Working backlog for admin-only capabilities. Account administration has its own backlog in [users-todo.md](users-todo.md); this file covers moderation of content sellers and buyers create.

Nothing here is required for the Phase 1 MVP. The listing side of a moderation delete is already built — taking a listing down, keeping it and its images as a backup, and a moderation-only view of what has been taken down — so several items below are an admin screen over behaviour that already exists rather than new behaviour. See [data-architecture.md](../architecture/data-architecture.md) for the soft-delete rules and [listings-todo.md](listings-todo.md) for what landed.

## NICE TO HAVE — Phase 2

### Moderation queue

- [ ] Buyer report action on a listing, feeding an admin moderation queue
- [ ] Queue triage: dismiss a report, or moderate the reported listing
- [ ] Admin trigger for taking a listing down — the soft delete itself, distinct from a seller's own delete, is already built and gated on the `listing:delete` permission
- [ ] Moderation view of listings that have been taken down, which is the only place the retained backup can be seen
- [ ] Restore a listing taken down in error, putting it back in the state it was in — without this a moderation delete is irreversible in practice, which is the one thing keeping the record was meant to avoid
- [ ] Automated moderation pattern matching on new listings, routing a match to the same queue
- [ ] The same pattern matching over comments and messages, which is where off-platform solicitation and spam actually happen — see [social-todo.md](social-todo.md)

### Dispute queue

- [ ] Queue of disputes awaiting an operator's decision, since no refund or return executes without one — see [disputes-todo.md](disputes-todo.md)
- [ ] Operator view of an order, both parties, the claim, and the evidence
- [ ] Operator resolution recorded against the decision-maker, since money moves on it

### Operational visibility

- [ ] Read-only view of orders and their states, for answering "where is my purchase" — see [orders-todo.md](orders-todo.md)
- [ ] Read-only view of a seller's balance and payout history — see [payments-todo.md](payments-todo.md)
- [ ] Audit log covering every operator edit to money or identity

### Marketplace settings

The settings record and the screen over it are built, and the values a marketplace tunes today live there: currency, the listing condition list, allowed image types, the image size cap, the image count bounds, the cart retention window, and the handle change cooldown. What the platform charges is a screen of its own, over two tables of named rows rather than one record. What remains is the values other areas have yet to build.

- [x] Move the tunable values into that settings record so an operator edits them rather than a deployer
- [x] Settings screen in the admin dashboard for editing them, with the platform defaults still applying wherever nothing has been set
- [ ] The listing field bounds in [listings-todo.md](listings-todo.md), the commission rule and completion window in [payments-todo.md](payments-todo.md), and the fulfillment methods in [shipping-todo.md](shipping-todo.md), as each is built
- [x] Admin CRUD for the seller deduction table — add, edit, and remove named rows, each a flat amount or a percentage of the price or of another row — see [payments 20](payments-todo.md)
- [x] Admin CRUD for the buyer fee table — add, edit, and remove named rows, each a flat amount or a percentage of the price — see [payments 21](payments-todo.md)
- [ ] The declared browse filters in [discovery-todo.md](discovery-todo.md), which stay in configuration for now: a facet declares where to read a value and how to parse it, which is a reference to code rather than a value an operator can type

## Waiting on

Nothing here is Phase 1, and most of it is a screen over behaviour another area owns:

| Area                                   | Why                                                                                   |
| :------------------------------------- | :------------------------------------------------------------------------------------ |
| [orders-todo.md](orders-todo.md)       | Purchases to read when answering "where is mine"                                      |
| [payments-todo.md](payments-todo.md)   | A seller balance and payout history to show, and the commission rule to make editable |
| [disputes-todo.md](disputes-todo.md)   | The queue an operator works through                                                   |
| [social-todo.md](social-todo.md)       | Comments and messages to moderate                                                     |
| [shipping-todo.md](shipping-todo.md)   | Methods and costs to make editable                                                    |
| [listings-todo.md](listings-todo.md)   | The field bounds to make editable. Already built, so this is satisfied                |
| [discovery-todo.md](discovery-todo.md) | The declared filters to make editable. Already built, so this is satisfied            |

## Depended on by

Every area that wants a value an operator can change, rather than a deployer, ends here:

| Area                                   | Why                                                           |
| :------------------------------------- | :------------------------------------------------------------ |
| [listings-todo.md](listings-todo.md)   | Field bounds                                                  |
| [discovery-todo.md](discovery-todo.md) | Declared browse filters                                       |
| [orders-todo.md](orders-todo.md)       | Completion window and reminder schedule                       |
| [payments-todo.md](payments-todo.md)   | Commission rule                                               |
| [shipping-todo.md](shipping-todo.md)   | Fulfillment methods and their costs                           |
| [disputes-todo.md](disputes-todo.md)   | Dispute window and reason list, and the operator queue itself |
| [social-todo.md](social-todo.md)       | The moderation queue a reported comment feeds                 |
| [reviews-todo.md](reviews-todo.md)     | The moderation queue a reported review feeds                  |
| [users-todo.md](users-todo.md)         | Moderation roles                                              |
