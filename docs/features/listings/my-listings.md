---
type: feature
title: My Listings
description: A trader's own view of everything they have listed, grouped by state.
tags: [listings, trader, ui]
timestamp: 2026-08-25T00:00:00Z
---

The page a signed-in trader reaches to see everything they have listed. Part of the listing backlog in [todo.md](todo.md); the rules the card and empty state it is built from follow are in [ui-components.md](../../architecture/ui-components.md).

Every account holds the trader role and can both buy and sell, so this is one of the two faces of an ordinary account rather than a separate kind of user — see [users.md](../../domain/users/users.md).

## What it shows

A trader sees the listings they put up and nobody else's, in every state a listing can be in — including the drafts and paused listings no public browse would return. A listing moderation has taken down is gone from the view.

Listings are grouped into a section per state, in the order Drafts, Live, Paused, Sold: the ones still owed work first, the ones kept only as a record last. A state with nothing in it has no section. Each section names how many listings it holds and what the state means for whoever listed them.

Within a section the most recently touched listing comes first, so an edit or a pause brings a listing back to the top.

Each listing shows its cover photo, price, state badge, title, and a line naming when it last moved — when a draft was saved, when a live listing was published, when a paused one was paused, when a sold one sold. A draft with no photo says so, since a photo is what publishing is waiting on.

## Filtering

A state filter narrows the page to one section. The chosen state lives in the address, so a filtered view can be shared or reached with the back button. A state the address names but the system does not recognise shows everything rather than an error.

Filter chips count the whole shelf, not the current filter, so they stay usable as a starting point. A trader with nothing listed is offered no chips.

## Emptiness

Two different empty views:

- A trader who has never listed anything gets an invitation to start, followed by the three steps a first listing takes.
- A filter matching nothing says which state is empty and offers a way back to everything.

## Available actions

Every listing offers the actions its state allows: continuing a draft, editing or pausing a live listing, relisting or editing a paused one, opening the order behind a sold one. Pausing, relisting and removing happen on this page, and the shelf is read again after each so the card, the section it sits in and the counts on the chips all describe the same snapshot. A relist has to clear the same bar publishing did, so one whose gallery fell below the marketplace's minimum while it was off offer is refused and told so. Removal is offered on anything except a sold listing, which is the record of a sale and cannot be removed, and asks for confirmation first.
