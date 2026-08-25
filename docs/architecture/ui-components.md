---
type: architecture
title: UI Components
description: The rules every Mercato UI component follows, and the variant vocabulary components name their states from.
tags: [ui, design, components]
timestamp: 2026-08-25T00:00:00Z
---

See [design-tokens.md](design-tokens.md) for the color, spacing, and radius values referenced here, [ui-guidelines.md](ui-guidelines.md) for the principles behind them, and [liveview.md](liveview.md) for which tier a component belongs in.

A component's own anatomy — its slots, its states, what a variant means for it — is documented on the component in code, which is the current and authoritative description of what that component does. This file holds what is true across all of them: the rules a new component follows, and the shared vocabulary it names its variants from.

## Shape

| Group | Rule |
|---|---|
| Radius | Controls 8, cards and sheets 12, chips/badges/avatars pill |
| Control heights | 32 / 36 / 44 / 52 |
| Borders | 1px standard, 1.5px for emphasis — inputs and selected states |
| Elevation | Subtle on a resting card, medium on hover and sticky bars, large on a sheet |

44 is the minimum touch target. A control below it is pointer-first: it belongs beside other small controls inside a card or a dense row, never as the only action on a screen.

## Color discipline

- The primary color belongs to actions and brand moments. It never sits behind a product photo.
- Filter chips stay black-and-white in both states, which is what keeps the primary color exclusive to actions.
- Accent marks a featured or highlighted record and the vibrant sale red marks a discount. Neither ever means "something is wrong" — the warning, error, and info tokens carry that.
- A disabled control is ink-100 with ink-300 text and no shadow, in every variant.

## Composition

- Anatomy is fixed, content is supplied. A component two features both render has one anatomy and two sets of slot content.
- A component that changes shape across widths renders one markup tree and switches in CSS, so a resize costs no re-render.
- Values arrive already formatted. A component that formatted money would have to know the record's currency.
- A control hugs its content; filling the row it sits in is opt-in.
- A component given a navigation target renders a link and renders a button otherwise, so one component covers acting and going somewhere.
- A collection that has never held anything and a filter matching nothing are two different empty states. The first explains how to start; the second names what is empty and offers a way back to everything.

## Accessibility baseline

- Labels are always visible. A placeholder is never the label.
- An error carries a message and a border. Color alone never carries a state.
- Focus is a 3px primary-100 ring.
- Decorative icons and placeholder artwork are hidden from screen readers.
- A section's heading is a heading, including when the section is empty.
- A table column can be marked as its row's header, and a table carries a caption available to screen readers only.
- Below its breakpoint a table renders one card per record, with each column's label shown beside its value.

## Variant vocabulary

The names a component draws from when it needs a variant. Which of these a given component implements is visible in that component's own documentation.

### Button variants

| Variant | Use |
|---|---|
| critical | The single highest-stakes action on a screen — pay, checkout. Used sparingly, above `primary` in emphasis. |
| primary | Main CTA — buy, publish |
| tertiary (primary border, no fill) | Offer / counter-offer |
| secondary | Social — follow |
| success | Confirm — accept offer |
| neutral | Cancel / secondary |
| danger | Destructive — decline offer, delete listing, remove account |

### Badge kinds

| Badge | Style |
|---|---|
| Featured | Accent background/text |
| New | Primary tint background, primary-700 text |
| Sale | Vibrant red (`#F5222D`) background, white text |
| Verified | Success green background/text |
| Warning | Warning amber background/text — a state that limits a record without ending it |
| Danger | Error red background/text — a state that stops a record |
| Info | Info blue background/text — a state a record has come to rest in |
| Neutral | ink-100 background, ink-700 text — anything with no state of its own |

## Navigation bar

Rounded card (radius 12) containing: logo, a pill-shaped search field (bg-2, radius pill), primary nav links, and a primary "Sell" button (sm).
