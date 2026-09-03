---
type: explore
title: Shipping Todo
description: Backlog of getting a bought listing to its buyer, split into Phase 1 MVP musts and Phase 2 nice-to-haves.
tags: [shipping, fulfillment, delivery, todo, backlog, mvp]
timestamp: 2026-09-03T00:00:00Z
---

Working backlog for how a bought listing reaches its buyer. The order it belongs to is [orders-todo.md](orders-todo.md); this file covers only the fulfillment of it.

Fulfillment is the part of a marketplace least alike between instances. One ships parcels through a carrier, one hands over a service at an appointment, one delivers a file on payment, one arranges collection in person. Everything here is therefore behind a configured method rather than assumed: **an instance that configures no fulfillment method still completes orders**, which is what lets a marketplace of services or digital goods use this starter kit without deleting anything.

Carriers are adapters behind a port, so the default needs no external account — see [ports.md](../architecture/ports.md).

- **MUST** — Phase 1 MVP: enough for a seller to fulfill and a buyer to know it happened.
- **NICE TO HAVE** — Phase 2: real carrier integration, depth, and the extension surface.

## MUST — Phase 1 MVP

### Fulfillment methods

1. [ ] Fulfillment methods declared by configuration, each stating what it needs from the seller before publishing and from the buyer at checkout
2. [ ] A manual method as the default: the seller says they have fulfilled, the buyer confirms — no carrier, no address validation, no external service
3. [ ] An instance configuring no method at all completes orders on the seller marking them fulfilled, for services and digital goods
4. [ ] The method in force decides what checkout asks the buyer for and what publish requires of the seller — needs [orders 10](orders-todo.md) and [orders 25](orders-todo.md)

### Addresses

5. [ ] Address as its own record a user may hold more than one of, since a seller's origin and a buyer's destination are different things and either may change
6. [ ] Address fields kept to what a generic address needs, with the format not assumed to be any one country's — needs [users 44](users-todo.md) for the account's side of it
7. [ ] An address is readable only by its owner and by the counterparty of an order it is fulfilling, and only while that order is live — needs [orders 1](orders-todo.md) for the order that makes someone a counterparty

### Cost

8. [ ] Fulfillment cost as its own line on the checkout breakdown rather than folded into the price — the breakdown is built and reads the items and the buyer fees already, so this is one more line to add to it — see [orders 11](orders-todo.md)
9. [ ] Who pays it — buyer, seller, or split — decided by configuration
10. [ ] A method that costs nothing shows no line, so a free or digital instance has no empty row — the breakdown already drops a line that comes to nothing, so this is a matter of the cost being read as such

## NICE TO HAVE — Phase 2

### Carriers

- [ ] Carrier port with an adapter for a multi-carrier provider, so a real label can be bought
- [ ] Label generation on fulfillment, delivered to the seller
- [ ] Live rate quotes at checkout rather than a configured cost
- [ ] Tracking status ingested from the carrier and reflected on the order
- [ ] Carrier-confirmed delivery as the trigger for the buyer's confirmation window, rather than the seller's word

### Depth

- [ ] Local collection and in-person handover as a method, with no address captured
- [ ] Appointment or time-slot booking, for a services marketplace
- [ ] Digital delivery — a file or a code released on completion
- [ ] Seller-funded fulfillment promotions, absorbing part of the cost to attract buyers — see [promotions-todo.md](promotions-todo.md)
- [ ] Address validation and autofill against a provider, as an opt-in adapter
- [ ] Exception handling: never collected, refused, returned to sender

### Extension surface

- [ ] Custom fulfillment method as a module a marketplace registers, contributing its own seller prerequisites, buyer fields, and states
- [ ] Admin-editable methods and costs rather than deploy-time — see [admin-todo.md](admin-todo.md)

## Waiting on

| Area | Why |
| :--- | :--- |
| [orders-todo.md](orders-todo.md) | There is nothing to fulfill until there is an order |
| [users-todo.md](users-todo.md) | The address record needs an account to hang off. Mutual: users waits on shipping for what an address holds and who may read it |
| [admin-todo.md](admin-todo.md) | Methods and their costs become operator-editable there, in Phase 2 |
| Notifications | Fulfilled, in transit, and delivered all need to reach a person; no area owns notifications yet |

## Depended on by

| Area | Why |
| :--- | :--- |
| [orders-todo.md](orders-todo.md) | The method in force decides what checkout asks for, and the fulfillment line on the cost breakdown |
| [users-todo.md](users-todo.md) | What an address holds and who may read it. Mutual |
| [disputes-todo.md](disputes-todo.md) | The return leg a refund may require, tracked like the outward one |
| [promotions-todo.md](promotions-todo.md) | A seller absorbing part of the fulfillment cost needs a cost to absorb |
| [admin-todo.md](admin-todo.md) | Methods and costs to make editable |
