---
type: explore
title: Payments Todo
description: Backlog of taking a buyer's money, holding it, and paying a seller out, split into Phase 1 MVP musts and Phase 2 nice-to-haves.
tags: [payments, escrow, payouts, commission, todo, backlog, mvp]
timestamp: 2026-09-01T00:00:00Z
---

Working backlog for the money in a purchase: charging the buyer, holding the funds while the order runs, and paying the seller out. What was bought and where it has got to is [orders-todo.md](orders-todo.md); this file covers only what happens to the money.

Escrow is the defining trait of the marketplace this starter kit describes — a buyer's payment is held until delivery is confirmed rather than passed straight to the seller. That hold is what makes [disputes-todo.md](disputes-todo.md) meaningful, and it is why this is its own area rather than a step inside checkout.

The provider is an adapter behind a port, so an instance can charge through one processor and pay out through another, or through none at all — a marketplace listing free items still has orders — see [ports.md](../architecture/ports.md). Charging and paying out are separate concerns and get separate behaviours, per the interface-segregation rule in [principles.md](../architecture/principles.md).

Balances live in a double-entry ledger: every money movement is an immutable set of postings against named accounts that sums to zero, and a balance is the sum of an account's postings. The ledger foundation is decided by a spike of the Ash double-entry extension on this project's data layer; if it does not hold up, the same model is built directly as accounts, entries, and postings with a sum-to-zero validation.

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
6. [ ] Releasing held funds is an operation of its own, separate from capturing them, and reversible after the fact so a dispute resolved late can claw money back
7. [ ] Order completion is what makes held funds payable — needs [orders 18](orders-todo.md)
8. [ ] Funds stay held while a dispute is open, and their fate is decided by the dispute's outcome — needs [disputes 9](disputes-todo.md)
9. [ ] Cancellation before fulfillment refunds the buyer in full

### The seller's balance

10. [ ] Seller balance showing pending earnings and payable earnings as two separate figures, since only one of them can be withdrawn
11. [ ] Platform commission deducted when earnings become payable, calculated by a configured rule
12. [ ] Seller requests a payout of their payable balance
13. [ ] Payout history the seller can read

### Money handling

14. [ ] Every amount stored as a minor-unit integer, never a float — the rule the listing price already follows
15. [ ] Every money movement recorded as a balanced set of postings against named accounts, so a balance is derived by summing postings rather than edited in place
16. [ ] Postings carrying their own currency, with an entry balancing within each currency it touches
17. [ ] A correction recorded as a new entry reversing the original, leaving the original untouched
18. [ ] Idempotency on charge and payout, so a retried request cannot take or send money twice
19. [ ] Ledger foundation chosen by a spike covering one escrow release with a commission split, since that flow is multi-legged and every order runs through it

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
| [orders-todo.md](orders-todo.md) | Funds are held against an order and released by its completion. Mutual: orders waits on payments in turn |
| [disputes-todo.md](disputes-todo.md) | A held payment cannot settle while a dispute is open, and the dispute's outcome is what decides it. Mutual: disputes waits on payments in turn |
| [admin-todo.md](admin-todo.md) | The commission rule becomes operator-editable there, in Phase 2 |
| Notifications | Payment received, payout sent, and payout failed all need to reach a person; no area owns notifications yet |

## Depended on by

| Area | Why |
| :--- | :--- |
| [orders-todo.md](orders-todo.md) | Checkout authorizes a payment before the order exists, and completion releases it. Mutual |
| [disputes-todo.md](disputes-todo.md) | A dispute decides the fate of held funds; without a hold it decides nothing. Mutual |
| [offers-todo.md](offers-todo.md) | An offer commits a buyer to a price, which is only binding if it can be charged |
| [listings-todo.md](listings-todo.md) | The net-payout estimate shown before publish needs the commission rule |
| [users-todo.md](users-todo.md) | Payout account details, and the credit a referral issues |
| [admin-todo.md](admin-todo.md) | A seller's balance and payout history to display, and the commission rule to make editable |
