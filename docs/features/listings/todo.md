---
type: feature
title: Listings Todo
description: Backlog of listing capabilities split into Phase 1 MVP musts and Phase 2 extension nice-to-haves.
tags: [listings, todo, backlog, mvp]
timestamp: 2026-08-20T00:00:00Z
---

Working backlog for the `Listing` entity — the thing a seller publishes and a buyer buys. "Listing" is the generic term so the starter kit covers goods, services, and rentals without biasing toward retail.

Flows referenced here are already specified in [commerce-ux-patterns.md](../../architecture/commerce-ux-patterns.md); this file tracks what to build, not how it should behave on screen. Per the minimal-core rule in [AGENTS.md](../../../AGENTS.md), a field lands in MUST only when Phase 1 cannot ship without it.

- **MUST** — Phase 1 MVP: list an item, find it, buy it. End-to-end and no further.
- **NICE TO HAVE** — Phase 2: the extension surface that lets any marketplace be built on top of Mercato.

## MUST — Phase 1 MVP

### Entity & attributes

- [ ] `Listing` resource with `seller_id`, `title`, `description`, `price`, `currency`, `quantity`, `status`, `published_at`, `created_at`, `updated_at`
- [ ] `Listing` belongs to a seller; a seller has many listings
- [ ] Price stored as a minor-unit integer, never a float
- [ ] Single currency for the whole instance, set by config
- [ ] Quantity defaults to 1; a completed purchase decrements it
- [ ] `condition` as a free enum with a config-supplied value list (new / like new / good / fair), so a non-goods marketplace can empty or replace it
- [ ] `Category` as a flat, seeded catalog with a listing belonging to one category
- [ ] Validation: title length bounds, price greater than zero, quantity non-negative, description length cap

### Media

- [ ] `ListingImage` with `listing_id`, `storage_key`, `position`, `is_cover`
- [ ] Upload through the existing storage port so the local-disk adapter is the default and Tigris stays opt-in — see [ports.md](../../architecture/ports.md)
- [ ] At least one image required to publish; a configurable maximum count
- [ ] Exactly one cover per listing, enforced at the data layer
- [ ] Server-side type and size validation on upload
- [ ] Deleting a listing deletes its stored objects

### Lifecycle

- [ ] States: `draft`, `active`, `unavailable`, `sold`, `deleted`
- [ ] `draft` is seller-only and becomes `active` on publish
- [ ] `active` is the only state visible in public browse and search
- [ ] `unavailable` is a reversible seller-initiated pause, visible only on the seller's own profile
- [ ] `sold` is set by the system when a purchase completes and is terminal
- [ ] A listing that reached `sold` cannot be deleted; it is retained as transaction history
- [ ] Seller-initiated delete on a never-sold listing is a real delete, freeing storage
- [ ] Moderation delete is a soft delete keeping an internal backup — see [data-architecture.md](../../architecture/data-architecture.md)
- [ ] Deleting a listing with a purchase in flight is refused or requires explicit confirmation

### Create & edit

- [ ] Single-form create; no multi-step stepper in Phase 1
- [ ] Draft auto-save so leaving the form does not lose work
- [ ] Edit any field while `draft` or `active`
- [ ] Publish and unpublish actions
- [ ] Publish blocked until the seller has a shipping-origin address on file

### Discovery

- [ ] Public browse grid of `active` listings, newest first
- [ ] Keyword search over title and description
- [ ] Filter by category, price range, and condition
- [ ] Sort by newest and by price ascending/descending
- [ ] Pagination or infinite scroll on the grid
- [ ] Listing detail page: image gallery, title, price, description, condition, seller card, buy action
- [ ] Public listing URLs use a slug or short id, stable across edits
- [ ] Seller's public profile lists their `active` listings first, `sold` and `unavailable` below

### Seller management

- [ ] "My Listings" view grouped by state with edit, pause, and delete actions
- [ ] Draft listings reachable from the same view

### Authorization

- [ ] Only the owning seller may edit, pause, or delete a listing
- [ ] Only `active` listings are readable by anonymous visitors
- [ ] Admins may moderate any listing
- [ ] A suspended or deleted seller's listings leave the public catalog

## NICE TO HAVE — Phase 2

### Extension surface

- [ ] Category-scoped attribute sets, so a fashion marketplace adds size/brand/color and a rentals marketplace adds duration/deposit without a schema change
- [ ] Pluggable listing-type modules that contribute their own fields, validations, and detail-page sections
- [ ] Search port with a SQLite FTS5 default adapter and an external engine as an opt-in adapter — see [full-text-search.md](../../explore/full-text-search.md)
- [ ] Configurable state machine so a marketplace can add states such as `reserved` or `pending_approval`
- [ ] Listing-created and listing-sold events other features can subscribe to

### Taxonomy

- [ ] Nested categories with breadcrumbs
- [ ] Brand, size, style, and color catalogs as optional seeded taxonomies
- [ ] Size charts scoped to a category
- [ ] Admin CRUD for every taxonomy

### Pricing & promotion

- [ ] Original-price field with strikethrough display
- [ ] "Lower price" action that notifies users who saved the listing
- [ ] Suggested-price hint from comparable sold listings
- [ ] Net-payout estimate shown before publish
- [ ] Seller-level and platform-level discount campaigns
- [ ] Curated collections placed into home and explore sections
- [ ] Offer and counter-offer negotiation on a listing

### Inventory & variants

- [ ] Variants — one listing, several purchasable options with their own price and stock
- [ ] Low-stock and out-of-stock handling distinct from `sold`
- [ ] Listing expiry with renew and relist
- [ ] Duplicate a listing to relist a similar item

### Media & authoring

- [ ] Drag-to-reorder images
- [ ] Server-side thumbnail generation and responsive image variants
- [ ] Video attachments
- [ ] Bulk upload — many images at once, grouped into per-listing drafts
- [ ] Field pre-fill from image analysis
- [ ] CSV import and export for sellers migrating a catalog

### Engagement & trust

- [ ] Save/favorite with a public favorite count on the card
- [ ] Recently viewed listings
- [ ] Similar listings and more-from-this-seller carousels
- [ ] Public comments on a listing
- [ ] Buyer report action with an admin moderation queue
- [ ] Automated moderation pattern matching on new listings
- [ ] Seller activity indicator on the card, derived from last-active time
- [ ] Per-listing view and conversion analytics for the seller — see [analytics-duckdb.md](../../explore/analytics-duckdb.md)

### Discovery depth

- [ ] Saved searches with new-match alerts
- [ ] Location-based filtering and local pickup
- [ ] Facet result counts on every filter option
- [ ] Sold-only filter with sold listings ranked last in general results
- [ ] Personalized ranking on home and explore
