---
type: domain
title: Carts
description: Business rules for a buyer's cart — the lines it holds, the seller grouping it reads in, and who may see one.
tags: [domain, carts, buying]
timestamp: 2026-09-01T00:00:00Z
---

A cart is what a buyer has gathered but not yet bought. It belongs to one person and holds one line per listing.

## Its own area

A cart is separate from an order. An order records what was bought and holds the terms it was bought on; a cart holds an intention and binds nobody to anything. A listing can leave a cart by being bought, by being removed, or by ceasing to be available, and none of those is a state an order has.

## A line

A line names a listing and how many of it the buyer wants. The quantity is at least one — a line of none is not an intention to buy, and removing the line is how a buyer says that.

Adding a listing already in the cart raises the quantity of the line that is there rather than making a second one. A buyer holds at most one line per listing, so a cart never has to be reconciled against itself.

A line also names the seller. It is recorded when the line is added rather than read back through the listing, because grouping a cart by seller is how it is read and how it will eventually be bought.

## No price

A line holds no price. What a listing costs is the listing's to say until a purchase agrees it, so a cart shows what the seller is asking now rather than what they were asking when the line was added. A seller repricing changes what the cart shows, which is the point: nothing has been agreed yet.

This is the opposite of an order, which copies the price at the moment of purchase precisely so a later change cannot rewrite it.

## Grouped by seller

A cart holds listings from any number of sellers at once, and reads as one group per seller. The grouping is not decoration: one seller's group is what becomes a single order, since one order covers one seller.

## What may be gathered

Only a listing the buyer can see may be added. A draft or a paused listing cannot be gathered any more than it can be bought.

## Who may see one

A cart is readable and changeable only by the person whose it is. Somebody else's line reads as absent rather than refused, and a person with nothing gathered reads an empty cart rather than an error.
