---
type: feature
title: Listing Detail Page
description: The public page one listing has of its own — what it shows, who may open it, and what each lifecycle state offers there.
tags: [listings, detail, buyer, gallery, purchase]
timestamp: 2026-08-26T00:00:00Z
---

The page a listing has of its own. It carries the whole buying decision — what the thing is, whether the seller can be trusted, what taking it costs — and is also the surface the purchase starts from.

Every listing on offer has one, at a URL built from the listing's own identifier. That URL is public: a visitor with no account reaches it, and no sign-in stands between arriving and starting a purchase.

## What the page holds

Two columns from `lg` up, one below it, in the same reading order at both widths.

The gallery takes the wider column and the largest area, followed by the description. Beside it sits the panel: the listing's title, its category and condition, the price, what is available, and the action. Reading the panel top to bottom answers what it is, whether it is worth it, and whether it can be had.

Who is selling follows the panel at every width — stacked under it on a phone, sharing its column on a desktop. Trust in the seller is the question that arrives after the price, so it is answered in that order whatever the layout.

The panel stays in view while the rest of the page scrolls past it. Below `lg` it scrolls with everything else, and the price and the action travel pinned to the bottom of the screen instead, so what is being committed to is never scrolled away from the control that commits to it.

The trail above the page is one level deep, because the catalog is flat.

## Who may open it

A listing on offer opens for everyone. A listing in any other state opens only for the seller who owns it.

A listing the visitor may not see is not distinguished from one that never existed. Draft, paused, sold, and unknown all read as the same statement: the listing is no longer available, it may have sold or been paused or been taken down, and the link itself is still good. Saying which would reveal what a seller holds.

## The seller's own view

The seller opening their own listing gets the same page, framed as what buyers see. A statement above the page says so, and everything except the panel is identical to the buyer's view — a preview that differed could not be used to check the listing.

The panel is the one part that swaps. Where a buyer finds the purchase action, the seller finds their own, so they learn where the buy action sits without a second layout, and the panel names what buyers see in that spot.

| State | What the seller is told | Primary | Secondary |
|---|---|---|---|
| `active` | The page is live and is shown exactly as buyers see it | Edit | Pause |
| `unavailable` | Nobody else can open the page, and the link reads as unavailable to buyers | Edit | Resume |
| `draft` | It was never published, is not searchable, and has no public link | Publish | Keep editing |

Pausing, resuming, and publishing happen on the page. Editing is a page of its own, so it is a link.

Views, saves, and other seller statistics are absent. This is the public page, and the seller's own measures of it belong to the view of everything they have listed.

## Availability and the purchase

The price is the single number the decision turns on, and the line under it qualifies rather than competes with it: how many are available, that none are left, or that the listing sold.

Purchase is the highest-stakes action on the page and is the only one styled as such. A listing whose seller has run out keeps the control and disables it, along with a line confirming nothing is charged — the listing is still on offer and stock can return. A listing that has sold gets a statement instead of a control, because a disabled purchase would imply it might come back.

A promise that payment is held until delivery is confirmed sits directly under the action, at caption weight. It answers the doubt that arrives at the moment of committing rather than earlier.

## The gallery

One photo fills the plate, at a fixed shape whatever the photo count, so the panel beside it holds the same position from listing to listing.

A gallery of one photo gets no strip and no counter. A larger gallery gets a strip beneath the plate and a count of the total on the plate itself, the total being a signal in its own right. A gallery larger than the strip shows a tile standing for the rest, sized like a photo so the row's rhythm holds; opening it reveals the remainder.

A listing with no photos gets a stated placeholder telling the buyer to ask for one before buying. Where the marketplace requires no minimum this is a permitted listing rather than a fault, so nothing about the placeholder reads as an error.

## Condition and description

Condition shows as a chip beside the category, worded the way a person writes it. A listing without one leaves nothing behind — the category simply sits alone.

The description keeps the blank lines the seller wrote as paragraph breaks, that being the only structure plain text carries. A listing without a description says so.

## The seller

Who is selling is shown as a row: their avatar, their name, and their handle.
