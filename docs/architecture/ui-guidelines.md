---
type: architecture
title: UI Guidelines
description: Guiding principles for Mercato's design system.
tags: [ui, design, ux, design-system]
timestamp: 2026-08-04T00:00:00Z
---

See also [design-tokens.md](design-tokens.md), [ui-components.md](ui-components.md), [commerce-ux-patterns.md](commerce-ux-patterns.md), and [accessibility-dark-mode.md](accessibility-dark-mode.md) for the rest of the design system. See [liveview.md](liveview.md), [heex-templates.md](heex-templates.md), [liveview-css.md](liveview-css.md), and [liveview-js.md](liveview-js.md) for the technical LiveView/HEEx/CSS standards that implement it.

## Customization model

Mercato ships with a default design system, meant to be adapted rather than used as-is. There are two levels of customization — see [design-tokens.md](design-tokens.md) for the mechanics of each:

1. **Theme config.** Swap colors, typography, spacing, radius, and shadows via Tailwind v4 `@theme` variables — the same "one config file" model as Bootstrap or Material UI theming. Covers a rebrand or visual refresh without touching component code.
2. **Component-level overrides.** For changes a token swap can't express — a different button shape, a bespoke card layout — edit the component directly (see [ui-components.md](ui-components.md)).

## Principles

- **The listing is the protagonist.** Surfaces are white with a clean, native feel. The primary color is reserved for actions and brand moments — never behind product photos.
- **Trust is visible.** Protection, verification, and seller stats surface at moments of doubt: on the listing page, in an offer, at checkout.
- **Designed for everyone.** The default palette and tone are neutral and broadly applicable across marketplace categories, not tuned to one niche.
- **Fast to sell.** "Sell" is always one tap away. A first listing takes under 2 minutes.
- Produce **world-class UI** with a focus on usability, aesthetics, and modern design principles.
- Implement **subtle micro-interactions** (button hover effects, smooth transitions).
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look.
- Focus on **delightful details**: hover effects, loading states, smooth page transitions.
