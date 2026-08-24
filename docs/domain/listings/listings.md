---
type: domain
title: Listings
description: Business rules for the Listing entity — ownership, price, quantity, category, condition, and lifecycle state.
tags: [domain, listings, marketplace, pricing, categories]
timestamp: 2026-08-24T00:00:00Z
---

A listing is what a seller publishes for a buyer to buy. The term is deliberately generic: the same entity covers physical goods, services, and rentals.

## Ownership

Every listing belongs to exactly one seller, and a seller may hold any number of listings. Ownership is fixed by whoever is acting when the listing is created — it is never supplied as part of the listing's content, so a listing cannot be created in another account's name.

## Description

A listing carries a title and an optional longer description. The title is required; a listing always has something to identify it by.

## Price and currency

A price is required and is held as a whole number of the currency's minor units — cents for a currency with hundredths, whole units for one without. Prices are never held as fractional amounts, so sums, fees, and payout splits stay exact rather than drifting by fractions of a unit.

The marketplace runs on a single currency. It is set for the whole instance and is not a per-listing choice; a seller has no say in it. Each listing records the currency in force when it was created, so a stored price stays unambiguous even if the instance is later reconfigured.

## Quantity

Quantity is how many units the listing offers. A listing offers one unit unless the seller says otherwise.

## Category

Every listing is filed under exactly one category, and a category holds any number of listings. Categories form a flat catalog: they have no parent and no nesting.

The catalog is fixed by the marketplace rather than by sellers — a seller picks from it and cannot add to it. Each category carries a display name and a stable identifier that survives a rename, so browsing a category keeps working after the name it shows changes.

## Condition

Condition describes the wear state of what is being sold. It is optional — a seller may leave it blank — and the values a seller may choose from are configured per marketplace rather than fixed by the platform.

This makes the field fit what is on sale: a marketplace selling used goods offers wear grades, a vehicle marketplace replaces them with its own, and one selling services or digital goods configures no values at all, which leaves condition blank on every listing.

A condition already recorded on a listing is retained if the marketplace later changes its list of values.

## Lifecycle state

Every listing holds one lifecycle state, and a new listing begins as a draft.

| State | Meaning |
|---|---|
| `draft` | Composed but not published; belongs to the seller alone |
| `active` | Published and offered to buyers |
| `unavailable` | Published earlier and paused by the seller |
| `sold` | Bought; no longer on offer |
| `deleted` | Withdrawn from the marketplace |

A listing also records when it was first published, which stays blank until publication. That stamp marks first publication rather than current visibility, so it survives a later pause.

## Timestamps

Every listing records when it was created and when it was last changed.
