---
type: guide
title: Customizing Styles & Components
description: How to rebrand or restyle a marketplace built on Mercato, from theme tokens down to individual components.
tags: [ui, design, theming, customization, guide]
timestamp: 2026-08-18T00:00:00Z
---

Mercato ships with a default design system meant to be forked and adapted, not used as-is (see [ui-guidelines.md#customization-model](../architecture/ui-guidelines.md#customization-model)). This guide walks through the three places you touch, in the order to try them.

## 1. Rebrand via theme tokens (try this first)

Colors, typography, spacing, radius, and shadows are all Tailwind v4 `@theme` variables in `assets/css/app.css`. Changing a marketplace's brand color, font, or corner roundness is a one-file edit here — no component code changes.

- Edit the `@theme { ... }` block in `assets/css/app.css`.
- [design-tokens.md](../architecture/design-tokens.md) is the reference for what each token controls and its usage rules (e.g. when to use `primary-500` vs `primary-700`).
- Rebuild CSS to see the change: `mix tailwind mercato` (or just let the running dev server recompile it).

This covers a full rebrand — new primary/secondary/accent colors, a different typeface, tighter/looser radius — without opening a single component file.

## 2. Override a shared component (token swap isn't enough)

For a change a token can't express — a different button shape, a new button/input variant, a different card layout — edit the component directly in `lib/mercato_web/components/core_components.ex`. This is the single source for atoms used across the whole app (`<.button>`, `<.input>`, `<.card>`, `<.accent_link>`, `<.table>`, `<.list>`, `<.flash>`), so a change here applies everywhere those are used.

- [ui-components.md](../architecture/ui-components.md) documents the intended spec (variants, heights, states) for each component — check it before diverging, and update it in the same change if you intend the new look to become the project's own convention.
- Follow [liveview-css.md](../architecture/liveview-css.md): components are hand-written Tailwind utility classes directly in the component's `~H` template, not `@apply`'d custom CSS classes and not a component library like daisyUI.
- Adding a genuinely new reusable atom (a badge, a chip)? Add it to `core_components.ex` alongside the existing ones, following the same pattern: `attr`/`slot` declarations, a `~H` template with literal Tailwind classes.

## 3. Add or change a feature-specific component

If a change only applies to one feature (a custom form layout, a one-off toggle like the auth pages' Password/Magic-link switcher), it doesn't belong in `core_components.ex`. Add or edit it inside that feature's own folder — see [liveview.md#component-structure](../architecture/liveview.md#component-structure) for the full rule. Promote it to `core_components.ex` only once a second feature would reuse it as-is.

## 4. Verify

After any of the above:

- `mix tailwind mercato` to confirm the CSS pipeline still compiles (a typo'd token or stray `@plugin` reference fails here first).
- `mix test` — component changes are exercised by the LiveView tests that render them.
- Click through the affected pages in a running `mix phx.server` — a passing test suite doesn't guarantee the visual result looks right.
