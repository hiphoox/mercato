---
type: domain
title: Orders
description: Business rules for the Order entity — the parties, the price agreed at purchase, quantity, lifecycle state, and who may see one.
tags: [domain, orders, purchase, marketplace, escrow, lifecycle]
timestamp: 2026-08-31T00:00:00Z
---

An order is one buyer's purchase of one seller's listing. It records what was bought and where it has got to; what happens to the money and how the goods travel are separate concerns, so a marketplace that charges nothing or ships nothing still has orders of this shape.

## The parties

Every order names three things that never change once it exists: the buyer who placed it, the seller who owes them, and the listing that was bought.

The buyer is whoever is acting when the order is placed — it is never supplied as part of the purchase, so an order cannot be placed in another account's name. The seller is taken from the listing rather than from the request, so the two can never disagree about who owes the buyer.

One order covers one seller. A purchase spanning two sellers is two orders, because each is fulfilled and paid out separately.

An order can only be placed against a listing the buyer can see, so a draft or a paused listing cannot be bought.

## Public reference

Every order carries a short public identifier, separate from the one the platform holds it by internally. It is eight characters drawn from digits and letters, with the characters a reader could mistake for one another left out, so it survives being quoted in a support conversation or read aloud.

The identifier is assigned when the order is placed and never changes. A buyer has no say in it and no way to supply one, and no two orders share one.

## The price agreed at purchase

An order records the listing's price as it stood at the moment of purchase, copied onto the order rather than read back from the listing. A seller repricing afterwards cannot rewrite what was agreed.

The price is per unit and is held as a whole number of the currency's minor units, the same form a listing's price takes. It is at least one minor unit. The currency is copied alongside it, so an order stays readable if the instance is later reconfigured.

The total is the price multiplied by the quantity. It is derived from the two rather than recorded separately, so the three can never disagree.

Neither the price nor the currency is something the buyer supplies.

## Quantity

Quantity is how many units were bought. An order is for one unit unless the buyer says otherwise, and never for none — buying none of something is not a purchase. This is the one part of the purchase the buyer decides.

## Lifecycle state

Every order holds one lifecycle state, and a new order begins as placed.

| State | Meaning |
|---|---|
| `placed` | Bought and paid for; the seller owes the buyer something |
| `fulfilled` | The seller has sent it, which opens the buyer's window to confirm |
| `completed` | Delivery confirmed; the purchase is done |
| `cancelled` | Called off before the seller fulfilled it |

An order moves between states only along these paths:

| From | To | Meaning |
|---|---|---|
| `placed` | `fulfilled` | The seller sends what was bought |
| `placed` | `cancelled` | Either party calls it off |
| `fulfilled` | `completed` | The buyer confirms delivery |

`completed` and `cancelled` lead nowhere, so an order that reaches either stays there.

Cancelling is deliberately unavailable once the seller has fulfilled. What a buyer wants at that point is the return of something already sent, which the marketplace treats as a dispute.

## Who sees an order

An order is visible to the buyer who placed it and the seller who is fulfilling it, and to nobody else. An order someone is not party to reads as absent rather than refused, so a list belonging to a stranger is empty rather than an error.

Moderation sees every order whoever the parties are, since an order is what a dispute or a refund is argued over.

## Timestamps

Every order records when it was placed and when it was last changed.
