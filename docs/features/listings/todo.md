---
type: feature
title: Listings Todo
description: Backlog of listing capabilities split into Phase 1 MVP musts and Phase 2 extension nice-to-haves.
tags: [listings, todo, backlog, mvp]
timestamp: 2026-08-24T00:00:00Z
---

Working backlog for the `Listing` entity — the thing a seller publishes and a buyer buys. "Listing" is the generic term so the starter kit covers goods, services, and rentals without biasing toward retail.

This file covers the listing entity itself — its fields, media, lifecycle, authoring, and ownership rules. A capability that introduces a *different* entity pointing at a listing belongs to that entity's area: browsing and search in [discovery/](../discovery/todo.md), favorites and comments in [social/](../social/todo.md), negotiation in [offers/](../offers/todo.md), discounts in [promotions/](../promotions/todo.md), performance metrics in [analytics/](../analytics/todo.md), and reports and moderation in [admin/](../admin/todo.md).

The Phase 1 MVP is "list an item, find it, buy it". *List it* is this file; *find it* is the discovery backlog. Neither area's Phase 1 is shippable alone.

Flows referenced here are already specified in [commerce-ux-patterns.md](../../architecture/commerce-ux-patterns.md); this file tracks what to build, not how it should behave on screen. Per the minimal-core rule in [AGENTS.md](../../../AGENTS.md), a field lands in MUST only when Phase 1 cannot ship without it.

- **MUST** — Phase 1 MVP: list an item, find it, buy it. End-to-end and no further.
- **NICE TO HAVE** — Phase 2: the extension surface that lets any marketplace be built on top of Mercato.

## MUST — Phase 1 MVP

### Entity & attributes

1. [x] `Listing` resource with `seller_id`, `title`, `description`, `price`, `currency`, `quantity`, `status`, `published_at`, `created_at`, `updated_at`
2. [x] `Listing` belongs to a seller; a seller has many listings
3. [x] Price stored as a minor-unit integer, never a float
4. [x] Single currency for the whole instance, set by config
5. [x] Quantity defaults to 1
6. [x] `condition` as a free enum with a config-supplied value list (new / like new / good / fair), so a non-goods marketplace can empty or replace it
7. [x] `Category` as a flat, seeded catalog with a listing belonging to one category
8. [x] Validation: title length bounds, price greater than zero, quantity non-negative, description length cap

### Media

9. [x] `ListingImage` with `listing_id`, `storage_key`, `position`, `is_cover`
10. [x] Upload through the existing storage port so the local-disk adapter is the default and Tigris stays opt-in — see [ports.md](../../architecture/ports.md)
11. [ ] Configurable minimum and maximum image count, defaulting to a minimum of one so a listing without photos is possible where the marketplace allows it
12. [x] Exactly one cover per listing, enforced at the data layer
13. [x] Server-side type and size validation on upload
14. [x] Deleting a listing deletes its stored objects

### Lifecycle

15. [x] States: `draft`, `active`, `unavailable`, `sold`, `deleted`
16. [x] `draft` is seller-only and becomes `active` on publish
17. [x] `active` is the only state visible in public browse and search
18. [x] `unavailable` is a reversible seller-initiated pause, visible only on the seller's own profile
19. [x] `sold` is set by the system when a purchase completes and is terminal
20. [ ] A listing that reached `sold` cannot be deleted; it is retained as transaction history
21. [ ] Seller-initiated delete on a never-sold listing is a real delete, freeing storage
22. [ ] Moderation delete is a soft delete keeping an internal backup — see [data-architecture.md](../../architecture/data-architecture.md)
23. [ ] Deleting a listing with a purchase in flight is refused or requires explicit confirmation

### Create & edit

24. [ ] Single-form create; no multi-step stepper in Phase 1
25. [ ] Draft auto-save so leaving the form does not lose work
26. [ ] Edit any field while `draft` or `active`
27. [ ] Publish and unpublish actions
28. [ ] Publish blocked until the seller satisfies the configured fulfillment prerequisites; the shipped-goods default requires a shipping-origin address, and a marketplace of services or digital goods configures none

### Public presentation

29. [ ] Listing detail page: image gallery, title, price, description, seller card, buy action, and condition where configured
30. [ ] Public listing URLs use a slug or short id, stable across edits
31. [ ] Seller's public profile lists their `active` listings first, `sold` and `unavailable` below

Browse, search, filtering, and sorting are in [discovery/todo.md](../discovery/todo.md).

### Seller management

32. [ ] "My Listings" view grouped by state with edit, pause, and delete actions
33. [ ] Draft listings reachable from the same view

### Authorization

34. [ ] Only the owning seller may edit, pause, or delete a listing
35. [ ] Only `active` listings are readable by anonymous visitors
36. [ ] Admins may moderate any listing
37. [ ] A suspended or deleted seller's listings leave the public catalog

## NICE TO HAVE — Phase 2

### Extension surface

38. [ ] Category-scoped attribute sets, so a fashion marketplace adds size/brand/color and a rentals marketplace adds duration/deposit without a schema change
39. [ ] Pluggable listing-type modules that contribute their own fields, validations, and detail-page sections
40. [ ] Configurable state machine so a marketplace can add states such as `reserved` or `pending_approval`
41. [ ] Listing-created and listing-sold events other features can subscribe to
58. [ ] Config-supplied field bounds — title length range, description cap, minimum price, maximum quantity — so a marketplace of one-line service listings and one of long-form vehicle listings both fit without a code change, and admin-editable rather than deploy-time — see [admin/todo.md](../admin/todo.md)

### Taxonomy

42. [ ] Nested categories with breadcrumbs
43. [ ] Optional seeded catalogs for whatever attributes a marketplace's categories need — brand, size, style, and color for fashion; make and model for vehicles
44. [ ] Category-scoped reference tables an attribute can be read against, such as a size chart
45. [ ] Admin CRUD for every taxonomy

### Pricing

46. [ ] Original-price field with strikethrough display
47. [ ] Net-payout estimate shown before publish — moves to a payments area once one exists

### Inventory & variants

48. [ ] Variants — one listing, several purchasable options with their own price and stock
49. [ ] Low-stock and out-of-stock handling distinct from `sold`
50. [ ] Listing expiry with renew and relist
51. [ ] Duplicate a listing to relist a similar item

### Media & authoring

52. [ ] Drag-to-reorder images
53. [ ] Server-side thumbnail generation and responsive image variants
54. [ ] Video attachments
55. [ ] Bulk upload — many images at once, grouped into per-listing drafts
56. [ ] Field pre-fill from image analysis
57. [ ] CSV import and export for sellers migrating a catalog
