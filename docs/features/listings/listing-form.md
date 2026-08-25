---
type: feature
title: Listing Form
description: The one page a trader composes a listing on, whether it is new or already theirs.
tags: [listings, trader, ui, form, authoring]
timestamp: 2026-08-25T00:00:00Z
---

The page a signed-in trader reaches to compose a listing. New and edit are one page: a listing is the same set of fields either way, so only the wording, the state badge, and what the primary action does differ. The rules governing the fields themselves are in [listings.md](../../domain/listings/listings.md), and the gallery's in [listing-images.md](../../domain/listings/listing-images.md).

Composing takes one page with no steps. A trader reaches it from the listing management view ([my-listings.md](my-listings.md)) — new from the page's own action, edit from a listing's.

## Who reaches it

A signed-out visitor is sent to sign in. A trader opening a listing that is not theirs is sent back to their own listings, and so is one opening a listing that is not there — the two are indistinguishable from the page, so a draft's existence is never confirmed to anyone but its owner.

An open listing is the trader's own in whatever state it holds, including the drafts and paused listings no public view would return.

## What it shows

Four sections, in the order a listing is built:

- **Photos** — the gallery in its order, the cover marked, a control to add more and one to remove or promote each. The count names how many the gallery holds against the marketplace's maximum, and the tile naming what may be added draws its file types and its limit from what the gallery actually accepts. A marketplace requiring no photos says the gallery is optional rather than telling the trader one is needed.
- **About the item** — title and description.
- **Price and stock** — price, quantity, category, and condition. The price is shown and typed in whole currency units, with the marketplace's currency named beside the box; what the listing stores is minor units. The category comes from the marketplace's seeded catalog, and the condition from the values the marketplace configures — a marketplace configuring none renders no condition control at all. Condition offers a way back to unstated, since a trader may leave it blank.
- **Save or publish** — the primary action, the secondary one, and what publishing still needs.

Below `lg` the sections stack in that order. From `lg` up, price and the actions move into a second column that stays in view while the first scrolls.

## What the actions say

The primary action names what will happen rather than which page it is on: a listing already on offer saves changes, and anything else publishes. A listing on offer offers pausing as the alternative; a draft has nothing to pause, so it is offered nothing.

The help beneath the actions names what publishing still needs, counted against the marketplace's own minimum — a marketplace requiring no photos asks only for a title and a price.

## What it says as it is filled in

The form answers as the trader types rather than holding its objections until they try to save. A field is marked and told what is wrong with it — a title too short to identify the item, a price the marketplace will not take — and the mark clears as soon as the field is right. A field the trader has not reached yet is never marked, so an empty form is not a page of complaints.

A price is read as the trader writes it, in whole currency units, and is refused rather than rounded when it carries more precision than the currency holds. What is typed stays in the box while it is being judged, so nothing is rewritten under the trader's cursor.

## What a refused publish looks like

A publish refused for want of photos marks the gallery section itself rather than the page, names what is missing, and says that nothing written was lost.
