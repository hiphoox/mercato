---
type: architecture
title: Responsive Layout
description: The breakpoint regimes the app layout adapts through, and how each is expressed.
tags: [ui, layout, responsive, breakpoints, css]
timestamp: 2026-08-19T00:00:00Z
---

The app layout adapts through four regimes, keyed to the theme's breakpoints. No custom
breakpoints are defined — a component reaches for `md:`, `lg:`, and `xl:` directly.

| Width | Sidebar | Header |
|---|---|---|
| `< md` | off-canvas drawer | wraps to two rows: controls above, search below |
| `md` – `lg` | off-canvas drawer | single row |
| `lg` – `xl` | icon rail by default | single row |
| `xl` and up | expanded by default | single row |

## One source of truth for the breakpoints

Retuning `--breakpoint-*` in `@theme` retunes the whole layout. Nothing restates a pixel
or `rem` value — not a component, not a media query, not JS:

- The `sidebar-collapsed` variant's media queries call `theme(--breakpoint-lg)` and
  `theme(--breakpoint-xl)`, resolved at build time.
- `--sidebar-mode` on `:root` names the live regime (`drawer`, `rail`, or `expanded`),
  switched by those same theme-driven media queries.
- The toggle hook reads `--sidebar-mode` off the computed style rather than running its
  own `matchMedia`, which is what keeps a breakpoint out of JS — where the theme token
  would not be reachable anyway.

## Sidebar state

Two independent pieces of client-only state, both attributes on `<html>`, both applied
before first paint so neither flashes:

- `data-sidebar-collapsed` — the user's rail preference. Tri-state: `true`, `false`, or
  absent. Absent means "use this width's default", which is why it is written only once
  the user has actually toggled. Persisted in `localStorage`.
- `data-sidebar-drawer` — `open` or `closed`. Only meaningful below `lg`. Not persisted:
  a drawer reopens closed on every page load.

The `sidebar-collapsed` CSS variant folds the width regime into itself, so a component
writes `sidebar-collapsed:w-18` once and gets all three behaviours. Below `lg` the variant
never matches, which is what leaves the drawer full width.

The toggle button resolves the current width's default before inverting it, so it always
changes something — on a small laptop, where the rail already shows, the first press
expands rather than appearing inert. Below `lg` the same button opens and closes the
drawer instead.

The drawer closes on outside click, on Escape, and on following a nav entry. It needs no
handling when the viewport widens past `lg`: the scrim is `lg:hidden` and the sidebar is
`lg:static`, so an open drawer state has no visible effect once the sidebar is in flow.

## Wrapping the header

Below `md` the header wraps and `order` rearranges it: the account control and cart stay
on the first row, search takes the second. The DOM order is unchanged, so reading and tab
order still follow the visual order at every width above `md` and remain sensible below it.

Search uses `grow basis-full`, not `flex-1`. The `flex` shorthand resolves `flex-basis` to
`0`, which would keep search on the first row instead of forcing the wrap.

## Verifying

Component tests can assert which classes and handlers are emitted; they cannot assert that
a breakpoint fires, because that is CSS applied against a real viewport. Confirm reflow by
resizing a browser. Confirm a custom variant actually generates CSS by building assets and
reading `priv/static/assets/css/app.css` — an unrecognised variant fails silently, emitting
nothing rather than erroring.
