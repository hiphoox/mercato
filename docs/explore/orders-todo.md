---
type: explore
title: Orders Todo
description: Backlog of the purchase a buyer makes on a listing and the order record it creates, split into Phase 1 MVP musts and Phase 2 nice-to-haves.
tags: [orders, purchase, cart, checkout, escrow, todo, backlog, mvp]
timestamp: 2026-09-01T00:00:00Z
---

Working backlog for buying a listing. An order is its own entity with its own lifecycle, payment state, and authorization rules, so a capability belongs here rather than in [listings-todo.md](listings-todo.md) whenever it is the order that governs it.

The Phase 1 MVP is "list an item, find it, buy it" — *buy it* is this file, *list it* is the listings backlog, and *find it* is [discovery-todo.md](discovery-todo.md). None of the three is shippable alone, and this is the one of the three still unbuilt.

The order owns *what was bought and where it has got to*. What happens to the money is [payments-todo.md](payments-todo.md), how the goods travel is [shipping-todo.md](shipping-todo.md), and what happens when the buyer is unhappy is [disputes-todo.md](disputes-todo.md). Those three are separate areas because a marketplace can swap any of them — a services marketplace ships nothing, a free marketplace charges nothing — without changing what an order is.

- **MUST** — Phase 1 MVP: enough for a buyer to buy a listing that exists and for both parties to see it through.
- **NICE TO HAVE** — Phase 2: depth, convenience, and the extension surface.

## MUST — Phase 1 MVP

### The order record

1. [x] `Order` resource with buyer, seller, listing, quantity, the price agreed at purchase, currency, status, and timestamps — the price is copied onto the order rather than read back from the listing, so a later price change cannot rewrite history
2. [x] One order covers one seller; a purchase spanning two sellers is two orders, since each is fulfilled and paid out separately
3. [x] Order states and their permitted transitions, with terminal states named
4. [x] Only the buyer and the seller of an order may read it; an admin may read any

### Cart

_The card's add-to-cart control already ships, drawn deliberately ahead of the cart it will write to._

5. [ ] A cart holding listings from several sellers at once, grouped by seller
6. [ ] A visitor may fill a cart without an account; it survives their session, and becomes theirs if they sign in
7. [ ] One checkout per seller group, since each group becomes its own order
8. [ ] What happens to a carted listing that sells to someone else first
9. [ ] Cart retention: how long a listing stays in a cart before it is dropped

### Checkout

10. [ ] Checkout reached either from a listing's buy action or from a seller group in the cart, stating what is being bought, from whom, and at what total
11. [ ] Checkout totals broken into their parts — item price, fulfillment cost where there is one, and platform fee where the instance charges one — rather than one opaque number
12. [ ] Buyer's fulfillment details captured at checkout where the instance requires them, prefilled from the account where there is one and editable — see [users-todo.md](users-todo.md)
13. [ ] Placing an order authorizes payment before the order exists, so an order is never created against a payment that failed — see [payments-todo.md](payments-todo.md)
14. [ ] A listing that sold while the buyer was in checkout fails the purchase rather than overselling
15. [ ] A visitor buys without creating an account, with account creation offered once the purchase is done
16. [ ] What identifies a guest buyer on their order, and how they reach it afterwards without signing in

### The purchase through to completion

17. [ ] Seller marks the order fulfilled, which is what starts the buyer's confirmation window
18. [ ] Buyer confirms delivery, completing the order
19. [ ] Automatic completion after a configured window with no confirmation and no dispute, so an inattentive buyer cannot strand a seller's money indefinitely
20. [ ] Completion is what releases the held payment — see [payments-todo.md](payments-todo.md)
21. [ ] Either party may cancel before fulfillment, refunding in full
22. [ ] A configured reminder schedule while an order waits on the seller to fulfill, and automatic cancellation at the end of it

### Effect on a listing

23. [ ] A purchase completing moves its listing to `sold` — the listing side of this already exists and is waiting to be called
24. [ ] Deleting a listing with a purchase in flight is refused or requires explicit confirmation — moved from [listings-todo.md](listings-todo.md), where it could not be built without an order to be in flight

### Fulfillment

25. [ ] Publish blocked until the seller satisfies the configured fulfillment prerequisites; the shipped-goods default requires a shipping-origin address, and a marketplace of services or digital goods configures none — moved from [listings-todo.md](listings-todo.md), where the rule lives on publish but the prerequisites do not exist to check. The seller address it needs is [users-todo.md](users-todo.md) item 44

### Seeing an order through

26. [ ] Buyer's own list of purchases, with each order's state and what it is waiting on
27. [ ] Seller's own list of sales, with the ones awaiting their action first
28. [ ] Order detail page showing what was bought, the cost breakdown, and a timeline of what has happened so far

## NICE TO HAVE — Phase 2

### Convenience & depth

- [ ] Partial fulfillment of a multi-quantity order
- [ ] Buyer-initiated cancellation request after fulfillment has been claimed but not evidenced
- [ ] Order-level notes or instructions from buyer to seller

### Extension surface

- [ ] Configurable order state machine, so a marketplace can add a state such as `awaiting_approval` or an inspection step between fulfillment and delivery
- [ ] Order-placed, order-fulfilled and order-completed events other areas subscribe to — the trigger for [reviews-todo.md](reviews-todo.md), [analytics-todo.md](analytics-todo.md), and notifications
- [ ] Configurable completion window and reminder schedule, admin-editable rather than deploy-time — see [admin-todo.md](admin-todo.md)

## Depended on by

An order is the event most other areas hang off. These are waiting on it:

| Area | What it needs |
| :--- | :--- |
| [payments-todo.md](payments-todo.md) | Something to hold funds against and release on |
| [shipping-todo.md](shipping-todo.md) | Something to generate a label for and track against |
| [disputes-todo.md](disputes-todo.md) | Something to dispute |
| [reviews-todo.md](reviews-todo.md) | A completed transaction to review |
| [offers-todo.md](offers-todo.md) | A checkout for an accepted offer to start |
