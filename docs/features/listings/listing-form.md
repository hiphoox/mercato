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

- **Photos** — the gallery in its order, the cover marked, a control to add more and one to remove or promote each. A photo belongs to a listing, so there is nothing to attach one to until the listing has been saved once: on a listing not yet saved the tile says so instead of taking a file. A gallery already holding the marketplace's maximum offers no way to add another rather than taking one and refusing it. The count names how many the gallery holds against the marketplace's maximum, and the tile naming what may be added draws its file types and its limit from what the gallery actually accepts. A marketplace requiring no photos says the gallery is optional rather than telling the trader one is needed.
- **About the item** — title and description.
- **Price and stock** — price, quantity, category, and condition. The price is shown and typed in whole currency units, with the marketplace's currency named beside the box; what the listing stores is minor units. The category comes from the marketplace's seeded catalog, and the condition from the values the marketplace configures — a marketplace configuring none renders no condition control at all. Condition offers a way back to unstated, since a trader may leave it blank.
- **Save or publish** — the primary action, the secondary one, and what publishing still needs.

Below `lg` the sections stack in that order. From `lg` up, price and the actions move into a second column that stays in view while the first scrolls.

## What the actions say

The primary action names what will happen rather than which page it is on: a listing already on offer saves changes, and anything else publishes. A listing on offer offers taking it off offer; a listing already off it offers putting it back; a draft has been on offer neither way, so it is offered neither. Putting one back has to clear the same bar publishing did, since it is the same move — a paused listing may lose photos while it is off offer, and one that has fallen below the marketplace's minimum is refused and told so on the gallery.

The action beside it follows the same rule. A listing not yet on offer can be put down and picked up again, kept as a draft without being shown to anyone. A listing already on offer has nothing to hold back, so what is offered instead is throwing away the changes on the page: it asks first, then puts back what was stored, having written nothing.

Every save says so, and says it where the trader is already looking rather than only on the page they land on next. A draft says it was kept as a draft; a listing on offer says its changes were saved; a publish refused for want of photos says both — that the draft was kept, and, on the gallery itself, why it is not on offer.

The help beneath the actions names what publishing still needs, counted against the marketplace's own minimum — a marketplace requiring no photos asks only for a title and a price.

## What it says as it is filled in

The form answers as the trader types rather than holding its objections until they try to save. A field is marked and told what is wrong with it — a title too short to identify the item, a price the marketplace will not take — and the mark clears as soon as the field is right. A field the trader has not reached yet is never marked, so an empty form is not a page of complaints.

A price is read as the trader writes it, in whole currency units, and is refused rather than rounded when it carries more precision than the currency holds. What is typed stays in the box while it is being judged, so nothing is rewritten under the trader's cursor.

## What a refused publish looks like

A publish refused for want of photos marks the gallery section itself rather than the page, names how many are still wanted, and says that nothing written was lost. It is not lost because it is saved: the listing is kept as a draft and the trader carries on editing that draft rather than starting again, so saving a second time changes the listing they already have instead of making another.
