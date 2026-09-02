---
type: domain
title: Marketplace Settings
description: The single set of values an operator tunes to fit what their marketplace sells, and what applies until they tune them.
tags: [domain, settings, admin, configuration]
timestamp: 2026-09-02T00:00:00Z
---

A marketplace runs on a handful of values that differ between instances: what it is priced in, what a listing may say about itself and show, how long a cart keeps an intention, how often an account may rename itself. They are held once for the whole platform and changed from the admin area.

## One set for the platform

There is a single set of settings, not one per seller, per category, or per listing. Every listing on an instance is priced in the same currency and offers the same conditions; a seller chooses among what the marketplace offers rather than extending it.

## What applies before anything is set

An instance nobody has tuned still runs. Each setting has a platform default that applies until an operator saves something over it, so a fresh install behaves like a general marketplace: priced in USD, offering the four ordinary conditions, accepting between one and ten JPEG, PNG or WebP images of up to 5 MB each, keeping an untouched cart line for 30 days, and letting an account change its handle once a month.

Saving settings for the first time is what brings the stored set into being. Until then nothing is stored and the defaults are what everyone reads.

## What is settable

| Setting | Governs |
| :--- | :--- |
| Currency | The single currency every price is denominated in, as an ISO 4217 code |
| Listing conditions | What a seller may say about the state of an item; empty drops the field from every listing |
| Image types | The media types a listing's gallery accepts |
| Largest image | The biggest file a gallery accepts |
| Fewest images | How few images a listing may go on offer with; zero drops the requirement |
| Most images | How many images a gallery holds |
| Cart retention | How long a line the buyer has not touched stays in their cart, set in whole days — see [carts](../carts/carts.md) |
| Handle change cooldown | How long an account waits between changing its handle — see [users](../users/er-diagram.md) |

## When a change takes effect

A saved setting applies to everything read from then on, with no deploy and no restart. What a change cannot do is rewrite what has already happened: a listing carries the currency it was created in, and an order carries the price it was bought at, so changing the marketplace's currency changes what new listings are priced in rather than what old ones cost.

A setting is read where it is used rather than held onto, so tightening the image count refuses the next gallery that exceeds it without touching the galleries that already do.

## Who may change them

Reading a setting is open to everyone, including a visitor with no account: a signed-out buyer browsing the grid is reading the currency and the condition list with every page.

Changing one is restricted to an operator granted the settings permission. It is a separate permission from reaching the admin area, so an operator can be given the moderation queues without being given the platform's own dials.
