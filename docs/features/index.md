---
type: index
title: Feature Docs
description: Map of docs/features/ — feature decisions, flows, and per-feature specs.
tags: [features, index]
timestamp: 2026-08-24T00:00:00Z
---

Map of `docs/features/`. Each subdirectory owns one feature area and has its own `index.md`.

- [admin/](admin/index.md) — Admin-only pages for running the platform: the users dashboard and the content moderation queue.
- [analytics/](analytics/index.md) — Seller-facing performance metrics for a listing.
- [discovery/](discovery/index.md) — Browsing, searching, filtering, and ranking listings.
- [listings/](listings/index.md) — The `Listing` entity a seller publishes and a buyer buys: its fields, media, lifecycle, and authoring.
- [offers/](offers/index.md) — Buyer offers and seller counter-offers on a listing.
- [orders/](orders/index.md) — Buying a listing: the purchase, the order record, escrow, delivery confirmation, and payout.
- [promotions/](promotions/index.md) — Discount campaigns and price-drop promotion.
- [social/](social/index.md) — Social interaction on a listing: favorites and public comments.
- [users/](users/index.md) — User accounts: signup, login, roles, permissions, and the account lifecycle backlog.

A capability that acts *on* a listing but introduces its own entity — a favorite, a comment, an offer, a report — belongs to that entity's area, not to `listings/`.
