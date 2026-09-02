---
type: domain
title: Carts
description: Business rules for a buyer's cart — the lines it holds, the seller grouping it reads in, whose it is, and who may see one.
tags: [domain, carts, buying, guest]
timestamp: 2026-09-02T00:00:00Z
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

## Checking out a group

A checkout covers one seller's group. A cart holding three sellers is checked out three times, each with its own total and each becoming its own order, and no total across sellers is ever charged.

A checkout reviews the group rather than offering a second cart: the same lines, with what each comes to and what the group comes to in total, and no way to change a quantity or drop a line without going back to the cart. The total covers the items and nothing else.

Buying a single listing from its own page gathers it into the cart first and goes on to that seller's checkout. A buyer who already had something of that seller's finds it in the same checkout, one seller being one purchase however its lines were gathered.

A checkout names the seller whose group it is. A seller whose group holds nothing buyable names no checkout, and neither does a seller who does not exist — both lead back to the cart, saying that what was there is no longer available. A group that emptied by lapsing is told apart from one that emptied any other way, and says that the cart cleared itself rather than that the goods went.

## When a listing stops being buyable

A listing leaves the marketplace while it sits in carts: somebody else buys it, the seller pauses it or runs out of it, the seller leaves the marketplace, moderation takes it down.

The line stays where the buyer put it and says it can no longer be bought. It counts for nothing while it is there — out of what its group comes to, out of what the cart comes to, out of both counts of how many things are gathered — and its group cannot be checked out until the buyer removes it.

The buyer keeps seeing what they gathered: the title and the photo of a listing they hold a line for stay readable to them whatever state it has since moved to, so a cart says which thing went rather than that something did. A listing moderation has taken down is the exception, being hidden from the buyer as well as from everyone else; that line says it went without saying what it was.

A listing its seller deletes outright leaves the carts holding it. There is nothing left to name, and a cart binds nobody, so it never stands between a seller and being rid of a listing.

## What may be gathered

Only a listing the buyer can see may be added. A draft or a paused listing cannot be gathered any more than it can be bought.

A seller may not gather their own listing: nobody buys from themselves, and the money would be going where it came from. Their own storefront and their own card in a grid offer them no way to, and a line gathered before signing in is dropped when the account it turns out to belong to claims the cart.

## What the count says

Every page carries the cart control, and it counts what the buyer has gathered: quantities rather than lines, so a line of three counts three, and only what can still be bought. A cart holding nothing buyable counts nothing at all.

Reading the count leaves a lapsed line where it is. The cart is what sweeps, so that a buyer meets the news on the page that can explain it rather than watching a figure fall on a page that cannot.

## How long a line keeps

A line stays in the cart for as long as the marketplace's retention window, counted from the last time the buyer touched it. Adding its listing again or changing how many they want renews it; opening the cart and scrolling past it does not.

Past that, the line is dropped outright. A buyer who comes back to a lapsed line finds it gone rather than marked, and adding the listing again starts a fresh line of one rather than restoring the quantity that lapsed. The window applies the same way to an account's cart and to a visitor's.

The window is set by the operator in whole days — see [marketplace settings](../settings/marketplace-settings.md) — because how long an intention to buy stays meaningful depends on what is being sold.

## Whose it is

A cart belongs either to an account or to a visitor without one. An account is needed neither to gather a cart nor to check one out, so a visitor gathers against a token their browser holds for the visit and reaches a checkout with it.

A line has one owner or the other, never both and never neither.

## Signing in

Signing in claims what the visitor gathered for the account, and the token keeps nothing. A listing the account had already gathered has the two quantities summed, the same as adding it twice would. A listing that stopped being buyable in the meantime is dropped, since a sign-in does not fail over something somebody else bought first.

From then on the visitor gathers into the account, not the token.

## Who may see one

A cart is readable and changeable only by the person whose it is — the account it belongs to, or whoever carries the token it was gathered against. Somebody else's line reads as absent rather than refused, and a person with nothing gathered reads an empty cart rather than an error.
