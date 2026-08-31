---
type: explore
title: Payments Todo
description: Backlog of taking a buyer's money, holding it, and paying a seller out, split into Phase 1 MVP musts and Phase 2 nice-to-haves.
tags: [payments, escrow, payouts, commission, todo, backlog, mvp]
timestamp: 2026-08-31T00:00:00Z
---

Working backlog for the money in a purchase: charging the buyer, holding the funds while the order runs, and paying the seller out. What was bought and where it has got to is [orders-todo.md](orders-todo.md); this file covers only what happens to the money.

Escrow is the defining trait of the marketplace this starter kit describes — a buyer's payment is held until delivery is confirmed rather than passed straight to the seller. That hold is what makes [disputes-todo.md](disputes-todo.md) meaningful, and it is why this is its own area rather than a step inside checkout.

The provider is an adapter behind a port, so an instance can charge through one processor and pay out through another, or through none at all — a marketplace listing free items still has orders — see [ports.md](../architecture/ports.md). Charging and paying out are separate concerns and get separate behaviours, per the interface-segregation rule in [principles.md](../architecture/principles.md).

- **MUST** — Phase 1 MVP: enough to take a payment, hold it, and pay a seller.
- **NICE TO HAVE** — Phase 2: depth, alternative instruments, and the extension surface.

## MUST — Phase 1 MVP

### The port

1. [ ] Charging behaviour: authorize, capture, and refund a buyer's payment, with the provider named by configuration
2. [ ] Payout behaviour: transfer a seller's balance out, separate from the charging behaviour so an instance can use one without the other
3. [ ] A no-op default that satisfies both behaviours, so a marketplace that moves no money still runs and the local development environment needs no external account
4. [ ] Provider webhooks reconciled against the order they belong to, since a payment's real state is the provider's rather than ours

### Holding and releasing

5. [ ] Funds captured at checkout are held by the platform rather than credited to the seller
6. [ ] Order completion is what makes held funds payable — see [orders-todo.md](orders-todo.md)
7. [ ] Funds stay held while a dispute is open, and their fate is decided by the dispute's outcome — see [disputes-todo.md](disputes-todo.md)
8. [ ] Cancellation before fulfillment refunds the buyer in full

### The seller's balance

9. [ ] Seller balance showing pending earnings and payable earnings as two separate figures, since only one of them can be withdrawn
10. [ ] Platform commission deducted when earnings become payable, calculated by a configured rule
11. [ ] Seller requests a payout of their payable balance
12. [ ] Payout history the seller can read

### Money handling

13. [ ] Every amount stored as a minor-unit integer, never a float — the rule the listing price already follows
14. [ ] Every money movement recorded as its own immutable record, so a balance is derived from what happened rather than edited in place
15. [ ] Idempotency on charge and payout, so a retried request cannot take or send money twice

## NICE TO HAVE — Phase 2

### Instruments

- [ ] Additional payment instruments beyond the default provider's, chosen by the buyer at checkout
- [ ] Platform credit a buyer can spend, issued by an operator
- [ ] Paying with earned balance, for a user who both buys and sells
- [ ] Splitting one payment across instruments

### Depth

- [ ] Negative balance, when a resolved dispute deducts more than a seller has, blocking payout until covered
- [ ] Seller onboarding with the payout provider deferred to the first payout request rather than required to start selling
- [ ] Partial refunds, and who bears the fulfillment cost on one
- [ ] Payout schedules — automatic on a cadence rather than requested by hand

### Extension surface

- [ ] Commission as a configured strategy rather than one rule, so an instance can charge a flat fee, a percentage, a tiered rate, or nothing
- [ ] Admin-editable commission and completion window rather than deploy-time — see [admin-todo.md](admin-todo.md)
- [ ] Tax as its own line item, calculated by a configured rule, since where it applies and who owes it varies by jurisdiction
- [ ] Payment events other areas subscribe to

## Waiting on

| Area | Why |
| :--- | :--- |
| [orders-todo.md](orders-todo.md) | Funds are held against an order and released by its completion |
| Notifications | Payment received, payout sent, and payout failed all need to reach a person; no area owns notifications yet |
