---
type: architecture
title: UI Components
description: Specs for Mercato's core UI components — buttons, form fields, badges, chips, tables, and the listing card.
tags: [ui, design, components]
timestamp: 2026-08-20T00:00:00Z
---

See [design-tokens.md](design-tokens.md) for the color, spacing, and radius values referenced here. These specs are the default implementation — Mercato's second level of customization is editing a component directly when a theme-token swap isn't enough (see [ui-guidelines.md](ui-guidelines.md#customization-model)).

## Buttons

Action buttons are rectangular with slightly rounded corners (radius 8). Heights are 32/36/44/52 (xs/sm/md/lg), semibold weight. Minimum touch target is 44×44.

| Variant | Use |
|---|---|
| critical | The single highest-stakes action on a screen — pay, checkout. Used sparingly, above `primary` in emphasis. |
| primary | Main CTA — buy, publish |
| tertiary (primary border, no fill) | Offer / counter-offer |
| secondary | Social — follow |
| success | Confirm — accept offer |
| neutral | Cancel / secondary |
| danger | Destructive — decline offer, delete listing, remove account |
| disabled | ink-100 background, ink-300 text, no shadow |

## Form Fields

- Labels are always visible — never use a placeholder as the label.
- Errors show a message and a red border — color alone never carries the error state.
- Focus state is a 3px primary-100 ring.
- Field height/padding: 11px 14px, radius 8, 1.5px border.

## Badges & Filter Chips

Filter chips: white background, black border; selected state is solid black. The primary color stays exclusive to actions.

| Badge | Style |
|---|---|
| Featured | Accent background/text |
| New | Primary tint background, primary-700 text |
| Sale | Vibrant red (`#F5222D`) background, white text |
| Verified | Success green background/text |
| Neutral (category, etc.) | ink-100 background, ink-700 text |

Removable filter chips (applied filters): white background, thin black border, height 24.

## Tables

One table component serves every tabular listing. Column headers stick to the top so they stay readable while the body scrolls, and each row is separated by a top border rather than shading.

A column can be marked as the row's header, so a screen reader announces which row a cell belongs to. A table carries a caption describing its contents, available to screen readers only.

Rows and individual cells can be styled from their own data — a deactivated record dimmed, a column hidden below a given breakpoint, a value kept on one line.

Below the table's breakpoint a listing renders as one card per record instead, with each column's label shown beside its value.

## Listing Card

Fixed anatomy: photo → title → price + discount (sale red) → seller with rating. Public heart/favorite count feeds "notify interested buyers" campaigns.

## Navigation Bar

Rounded card (radius 12) containing: logo, a pill-shaped search field (bg-2, radius pill), primary nav links, and a primary "Sell" button (sm).
