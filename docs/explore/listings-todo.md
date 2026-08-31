---
type: explore
title: Listings Todo
description: Backlog of listing capabilities split into Phase 1 MVP musts and Phase 2 extension nice-to-haves.
tags: [listings, todo, backlog, mvp]
timestamp: 2026-08-31T00:00:00Z
---

Working backlog for the `Listing` entity — the thing a seller publishes and a buyer buys. "Listing" is the generic term so the starter kit covers goods, services, and rentals without biasing toward retail.

This file covers the listing entity itself — its fields, media, lifecycle, authoring, and ownership rules. A capability that introduces a *different* entity pointing at a listing belongs to that entity's area: browsing and search in [discovery-todo.md](discovery-todo.md), favorites and comments in [social-todo.md](social-todo.md), negotiation in [offers-todo.md](offers-todo.md), the purchase itself in [orders-todo.md](orders-todo.md), discounts in [promotions-todo.md](promotions-todo.md), performance metrics in [analytics-todo.md](analytics-todo.md), and reports and moderation in [admin-todo.md](admin-todo.md).

The Phase 1 MVP is "list an item, find it, buy it". *List it* is this file; *find it* is the [discovery-todo.md](discovery-todo.md) backlog; *buy it* is the [orders-todo.md](orders-todo.md) backlog. No area's Phase 1 is shippable alone.

Flows referenced here are already specified in [commerce-ux-patterns.md](../architecture/commerce-ux-patterns.md); this file tracks what to build, not how it should behave on screen. Per the minimal-core rule in [AGENTS.md](../../AGENTS.md), a field lands in MUST only when Phase 1 cannot ship without it.

- **MUST** — Phase 1 MVP: list an item, find it, buy it. End-to-end and no further.
- **NICE TO HAVE** — Phase 2: the extension surface that lets any marketplace be built on top of Mercato.

## MUST — Phase 1 MVP

### Entity & attributes

1. [x] `Listing` resource with `seller_id`, `title`, `description`, `price`, `currency`, `quantity`, `status`, `published_at`, `inserted_at`, `updated_at`
2. [x] `Listing` belongs to a seller; a seller has many listings
3. [x] Price stored as a minor-unit integer, never a float
4. [x] Single currency for the whole instance, set by config
5. [x] Quantity defaults to 1
6. [x] `condition` as a free enum with a config-supplied value list (new / like new / good / fair), so a non-goods marketplace can empty or replace it
7. [x] `Category` as a flat, seeded catalog with a listing belonging to one category
8. [x] Validation: title length bounds, price greater than zero, quantity non-negative, description length cap

### Media

9. [x] `ListingImage` with `listing_id`, `storage_key`, `position`, `is_cover`
10. [x] Upload through the existing storage port so the local-disk adapter is the default and Tigris stays opt-in — see [ports.md](../architecture/ports.md)
11. [x] Configurable minimum and maximum image count, defaulting to a minimum of one so a listing without photos is possible where the marketplace allows it
12. [x] Exactly one cover per listing, enforced at the data layer
13. [x] Server-side type and size validation on upload
14. [x] Deleting a listing deletes its stored objects
59. [x] Gallery authorization: only a listing's own seller may add, reorder, promote or remove its images — the listing itself is guarded, its images are not

### Lifecycle

15. [x] States: `draft`, `active`, `unavailable`, `sold`, `deleted`
16. [x] `draft` is seller-only and becomes `active` on publish
17. [x] `active` is the only state visible in public browse and search
18. [x] `unavailable` is a reversible seller-initiated pause, visible only on the seller's own profile
19. [x] `sold` is set by the system when a purchase completes and is terminal
20. [x] A listing that reached `sold` cannot be deleted; it is retained as transaction history
21. [x] Seller-initiated delete on a never-sold listing is a real delete, freeing storage
22. [x] Moderation delete is a soft delete keeping an internal backup — see [data-architecture.md](../architecture/data-architecture.md)

### Create & edit

24. [x] Single-form create; no multi-step stepper in Phase 1
25. [x] Draft auto-save so leaving the form does not lose work — the draft comes into being as soon as the form holds a title, a price and a category, and keeps itself from then on; a listing that has been on offer is saved only when the seller asks, so buyers never see a half-finished thought
26. [x] Edit any field while `draft` or `active`
27. [x] Publish and unpublish actions

Publishing blocked on the seller's fulfillment prerequisites has moved to [orders-todo.md](orders-todo.md), which governs fulfillment.

### Public presentation

29. [x] Listing detail page: image gallery, title, price, description, seller card, buy action, and condition where configured
30. [x] Public listing URLs use a slug or short id, stable across edits
31. [x] Seller's public profile lists their `active` listings first and `sold` below; `unavailable` appears nowhere, since pausing is how a seller takes a listing out of public view

Browse, search, filtering, and sorting are in [discovery-todo.md](discovery-todo.md).

### Seller management

32. [x] "My Listings" view grouped by state with edit, pause, and delete actions
33. [x] Draft listings reachable from the same view

### Authorization

34. [x] Only the owning seller may edit, pause, or delete a listing
35. [x] Only `active` listings are readable by anonymous visitors
36. [x] Admins may moderate any listing
37. [x] A suspended or deleted seller's listings leave the public catalog

## NICE TO HAVE — Phase 2

### Extension surface

38. [ ] Category-scoped attribute sets, so a fashion marketplace adds size/brand/color and a rentals marketplace adds duration/deposit without a schema change
39. [ ] Pluggable listing-type modules that contribute their own fields, validations, and detail-page sections
40. [ ] Configurable state machine so a marketplace can add states such as `reserved` or `pending_approval`
41. [ ] Listing-created and listing-sold events other features can subscribe to — the sold event is raised by order completion, see [orders-todo.md](orders-todo.md)
58. [ ] Config-supplied field bounds — title length range, description cap, minimum price, maximum quantity — so a marketplace of one-line service listings and one of long-form vehicle listings both fit without a code change, and admin-editable rather than deploy-time — see [admin-todo.md](admin-todo.md)

### Taxonomy

42. [ ] Nested categories with breadcrumbs
43. [ ] Optional seeded catalogs for whatever attributes a marketplace's categories need — brand, size, style, and color for fashion; make and model for vehicles
44. [ ] Category-scoped reference tables an attribute can be read against, such as a size chart
45. [ ] Admin CRUD for every taxonomy

### Pricing

46. [ ] Original-price field with strikethrough display
47. [ ] Net-payout estimate shown before publish — needs the commission rule in [payments-todo.md](payments-todo.md)

### Inventory & variants

48. [ ] Variants — one listing, several purchasable options with their own price and stock
49. [ ] Low-stock and out-of-stock handling distinct from `sold`
50. [ ] Listing expiry with renew and relist
60. [ ] Seller nudges over a stale catalog — a listing long unsold prompting a price drop, a listing long unedited prompting a refresh, a periodic prompt to confirm what is still available — so a catalog stops accumulating items the seller no longer has
51. [ ] Duplicate a listing to relist a similar item

### Media & authoring

52. [ ] Drag-to-reorder images
53. [ ] Server-side thumbnail generation and responsive image variants
54. [ ] Video attachments
55. [ ] Bulk upload — many images at once, grouped into per-listing drafts
56. [ ] Field pre-fill from image analysis
57. [ ] CSV import and export for sellers migrating a catalog
