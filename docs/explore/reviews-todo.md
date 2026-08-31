---
type: explore
title: Reviews Todo
description: Backlog of the reputation two parties build by trading with each other, split into Phase 1 MVP musts and Phase 2 nice-to-haves.
tags: [reviews, ratings, reputation, trust, todo, backlog]
timestamp: 2026-08-31T00:00:00Z
---

Working backlog for the reputation a user accrues by trading. A review belongs to a finished order rather than to a listing or a person, which is why it is its own area — see [orders-todo.md](orders-todo.md).

Reputation is what a peer-to-peer marketplace substitutes for a brand. A buyer choosing between two strangers selling the same thing has the sellers' histories to go on and little else, which is why this is a common feature rather than a luxury. It is not Phase 1: a first purchase can complete without anyone having a rating, and a rating system with no completed orders behind it has nothing to display.

**Only a finished order produces a review.** A review that anyone can leave about anyone is a comment, not a reputation — see [social-todo.md](social-todo.md) for those.

## NICE TO HAVE — Phase 2

### Leaving one

- [ ] Either party of a completed order may review the other, once
- [ ] A review is a rating plus optional words
- [ ] A review window that closes, so a reputation reflects recent trading rather than staying open forever
- [ ] An order that ended in a dispute is reviewable; one cancelled before fulfillment is not, since neither party did anything to be judged on
- [ ] A review cannot be edited once the other party can see it

### Not seeing it coming

- [ ] Neither party sees the other's review until both have left one or the window closes, so a review is an account of the trade rather than a reply to one
- [ ] A party who left nothing before the window closed forfeits their turn, and the other's review publishes regardless

### Showing it

- [ ] Reviews on a user's public profile, most recent first
- [ ] An aggregate rating on the profile and on the seller card a listing carries
- [ ] The count alongside the average, since one five-star trade is not a reputation
- [ ] A user with too few reviews shows none rather than a misleading average

### Depth & extension surface

- [ ] Right of reply, so a seller can answer a review without being able to remove it
- [ ] Reporting a review into the same moderation queue as a reported listing — see [admin-todo.md](admin-todo.md)
- [ ] Reputation as a signal in discovery ranking — see [discovery-todo.md](discovery-todo.md)
- [ ] Configurable rating shape, so an instance can use stars, a thumb, or its own scale
- [ ] Per-role reviews, where being a good buyer and a good seller are scored separately

## Waiting on

| Area | Why |
| :--- | :--- |
| [orders-todo.md](orders-todo.md) | Only a completed order produces a review; this cannot start before orders ship |
| [disputes-todo.md](disputes-todo.md) | Whether an order ended in a dispute changes whether it is reviewable |
| Notifications | A review window opening and closing needs to reach a person; no area owns notifications yet |

## Related

[principles.md](../architecture/principles.md) uses a seller rating as its worked example of extending a resource by adding an attribute rather than rewriting it. That is this area — the example is not hypothetical, it is unbuilt.
