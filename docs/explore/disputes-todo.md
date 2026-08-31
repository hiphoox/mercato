---
type: explore
title: Disputes Todo
description: Backlog of what happens when a buyer is unhappy with a completed purchase, split into Phase 1 MVP musts and Phase 2 nice-to-haves.
tags: [disputes, returns, refunds, escrow, todo, backlog, mvp]
timestamp: 2026-08-31T00:00:00Z
---

Working backlog for what happens when a purchase goes wrong. The order it is raised against is [orders-todo.md](orders-todo.md), and the held funds it decides the fate of are [payments-todo.md](payments-todo.md).

This area exists because escrow demands it. Holding a buyer's payment until delivery is confirmed only protects anyone if there is a way to say "this was not what I bought" before the hold releases — without that, the hold is a delay rather than a protection. A dispute is therefore the counterpart of the completion window, not an administrative afterthought.

**The governing rule: no refund or return executes without an operator deciding it.** A seller agreeing with the buyer is not enough. If it were, two colluding accounts could run purchases and refunds against each other repeatedly and leave the platform carrying the fulfillment and processing costs of sales that never happened.

- **MUST** — Phase 1 MVP: enough that a buyer who did not get what they paid for can say so, and an operator can resolve it.
- **NICE TO HAVE** — Phase 2: depth, automation, and the extension surface.

## MUST — Phase 1 MVP

### Raising one

1. [ ] Buyer raises a dispute against a delivered order, within the confirmation window
2. [ ] Raising one holds the order short of completion and keeps the funds held past the window they would otherwise release on
3. [ ] Dispute reasons declared by configuration, since what can go wrong differs by what is being sold
4. [ ] Buyer states what went wrong, with evidence attached — reusing the storage port the listing gallery already uses, see [ports.md](../architecture/ports.md)

### Resolving one

5. [ ] Seller sees the dispute and responds, agreeing or contesting
6. [ ] Every dispute reaches an operator queue regardless of what the seller said, since agreement alone cannot move money
7. [ ] Operator sees the order, both parties, what was claimed, and the evidence, and decides
8. [ ] Outcomes: refund the buyer in full, refund in part, or complete the order in the seller's favour
9. [ ] The outcome is what settles the held funds — see [payments-todo.md](payments-todo.md)
10. [ ] Dispute states and their terminal transitions, with an order unable to complete while one is open

### Authorization & record

11. [ ] A dispute is readable only by its buyer, its seller, and an operator
12. [ ] Every decision recorded with who made it and when, since money moved on it

## NICE TO HAVE — Phase 2

### Returns

- [ ] Return leg: the buyer sends the item back before a refund executes, tracked like the outward leg — see [shipping-todo.md](shipping-todo.md)
- [ ] Who pays the return cost, decided by the outcome
- [ ] Refund conditional on the return arriving, rather than on the decision alone

### Depth

- [ ] Direct negotiation between buyer and seller before an operator is involved, resolving the easy cases without one — needs private messaging, which no area owns yet
- [ ] Deducting a resolved dispute from a seller's balance, and the negative balance that follows — see [payments-todo.md](payments-todo.md)
- [ ] A seller's dispute rate feeding their account standing — see [users-todo.md](users-todo.md)
- [ ] Buyer-side abuse handling, for an account that disputes everything
- [ ] Operator requesting more evidence rather than deciding on what is there

### Extension surface

- [ ] Configurable outcomes and the refund treatment each implies, so an instance can add its own
- [ ] Admin-editable dispute window and reason list rather than deploy-time — see [admin-todo.md](admin-todo.md)
- [ ] Dispute-opened and dispute-resolved events other areas subscribe to

## Waiting on

| Area | Why |
| :--- | :--- |
| [orders-todo.md](orders-todo.md) | There is nothing to dispute until an order can complete |
| [payments-todo.md](payments-todo.md) | A dispute decides the fate of held funds; without a hold it decides nothing |
| [admin-todo.md](admin-todo.md) | Every dispute ends at an operator queue |
| Notifications | Raised, responded to, and resolved all need to reach a person; no area owns notifications yet |
