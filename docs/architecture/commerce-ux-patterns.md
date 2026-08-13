---
type: architecture
title: Commerce UX Patterns
description: Interaction patterns for browsing, purchasing, selling, and order tracking — proven e-commerce conventions plus C2C-specific patterns.
tags: [ui, ux, commerce, patterns]
timestamp: 2026-08-13T00:00:00Z
---

See [ui-components.md](ui-components.md) for the buttons, badges, and chips used in these patterns.

## Discovery & Browsing

Proven across major e-commerce sites (Amazon, Etsy, eBay), independent of category or pricing model:

- **Search & filters**: persistent search bar plus faceted filters (category, price range, condition, location); applied filters render as removable chips with a visible result count.
- **Sort**: relevance (default), price (asc/desc), newest — a dropdown or bottom sheet on mobile, never buried in a secondary menu.
- **Breadcrumbs**: category path on listing and category pages, so backing out doesn't mean re-searching.
- **Related / similar listings**: a horizontal carousel on the listing page ("More like this," "From this seller") to keep browsing going after a view.

## Trust Signals

- **Reviews & ratings**: aggregate star rating plus count on both the listing and the seller card; individual reviews show reviewer name, rating, date, and text — sortable by recency or rating.
- **Seller card**: avatar, name, verified badge, rating, sales count, average response time, Follow (secondary) button.
- **Protection messaging**: a persistent, low-emphasis banner at checkout and on the listing page stating the platform's escrow/buyer-protection guarantee. This is a proven pattern for reducing checkout drop-off on peer-to-peer marketplaces — eBay's Money Back Guarantee and Airbnb's payment protection banner are the reference implementations.

## Fixed-Price Purchase (baseline)

The default, always-available path — standard e-commerce, no negotiation required:

- **Listing page**: price, a primary "Buy" button, quantity/variant selectors where applicable.
- **Wishlist / save**: a heart/save toggle on the listing card and listing page, with a dedicated "Saved" view — intent tracking, no negotiation implied.

## Cart & Checkout

- **Cart** (drawer on desktop, full page on mobile): line items with thumbnail, title, price, quantity stepper, and remove action; subtotal updates live as quantities change; a `critical`-variant "Checkout" button (see [ui-components.md](ui-components.md)).
- **Empty cart**: same empty-state pattern as elsewhere (see [Notifications & Feedback](#notifications--feedback)) with a primary action back to browsing.
- **Cart persistence**: a signed-in user's cart survives across sessions and devices; a guest's cart survives the session at minimum.
- **Guest checkout**: purchasing without creating an account first is available by default — requiring account creation before checkout is a proven source of cart abandonment. Account creation can still be offered post-purchase.
- **Checkout steps**: Shipping address → Shipping method (cost + ETA shown per option) → Payment → Review. A returning buyer with a saved address and payment method can collapse this to a single review-and-confirm screen.
- **Address book**: saved shipping addresses, selectable at checkout, editable without leaving the flow.
- **Payment methods**: saved cards/methods shown first, "add new" as a secondary path; the payment step never redirects to a separate unbranded page if it can be avoided.
- **Order review**: a final summary (items, shipping, fees, total) before the charge — the buyer confirms what they're paying before, not after, the charge happens.
- **Order confirmation**: an on-screen confirmation with order number immediately after purchase, plus an email receipt — a purchase is never confirmed by silence.

## Offer & Negotiation (optional layer)

Common across C2C peer marketplaces but not part of every marketplace's model — enable this layer only if negotiated pricing fits the target marketplace:

- **Offer bar** (sticky on listing page): current price + strikethrough original price, "Offer" (tertiary) and "Buy" (primary) buttons.
- **Offer sheet**: suggested discount chips (e.g. −10%/−15%/−20%), an editable price input, a primary "Make offer" button, and an expiry/protection hint below it.
- **Negotiation thread**: a dedicated offer-message card in chat with Accept (success) / Decline (danger) / Counter-offer (tertiary) actions. Quick-reply chips (e.g. "Still available?", "Is that the lowest?") sit below the input.

## Order Lifecycle & Tracking

- **Status stepper**: Placed → Paid → Shipped → Delivered → Funds Released, shown on the order detail view — matching the platform's actual escrow-release milestones, not a generic label set.
- **Status-change notifications**: shipped, delivered, and funds-released events use the patterns in [Notifications & Feedback](#notifications--feedback).
- **Dispute entry point**: a visible "Report a problem" action once an order reaches Delivered, time-boxed to the platform's buyer-protection window.

## Sell / Listing Creation Flow

- **Stepper**: Photos → Details → Price → Shipping → Publish, with progress always visible and a draft auto-saved between steps — leaving mid-flow never loses work.
- **Photos**: multi-upload with drag-to-reorder; the first photo is the cover shown everywhere else (listing card, search results). A first-listing tip nudges toward more photos — listings with more photos consistently convert better, across categories.
- **Category & attributes**: a guided category picker (search-as-you-type, not a deep static tree) that reveals category-specific attribute fields (condition, size, brand, etc.) only once a category is chosen, not all fields up front.
- **Pricing help**: a net-payout estimate based on similar sold items ("You'll receive $X after commission — no surprises") shown before publish, plus a suggested price range from comparable listings.
- **Shipping setup**: who pays (buyer/seller/free), package weight/dimensions for carrier rate calculation, and a local-pickup toggle where relevant.
- **Inventory**: a quantity field for sellers listing multiple units of the same item, so a sale decrements stock rather than requiring a manual relist.
- **Listing management**: edit, pause/unpublish, duplicate (relist a similar item fast), and renew an expired listing — all reachable from a single "My Listings" view, not buried per-listing.

## Notifications & Feedback

- **In-app notification center**: a bell icon with an unread-count badge, opening a chronological list (new message, new offer, order status change, price drop on a saved item) — each entry deep-links to its source.
- **Push & email**: every state change a user isn't actively looking at (shipped, delivered, offer received, message received) triggers a push notification and/or email — never a silent state change a user has to poll for.
- **Toasts**: a transient, non-blocking confirmation for an action just taken ("Added to cart", "Offer sent") — auto-dismisses, never blocks the next action.
- **Alerts**: success / info / warning / error, each with an icon plus a bold headline and supporting text — never color alone.
- **Empty state**: centered icon, bold headline, short supporting text, primary action button.
- **Loading state**: skeleton screens for content-heavy views (listing grids, order history) rather than a blocking spinner — perceived performance is measurably better.
