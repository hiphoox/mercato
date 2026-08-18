---
type: architecture
title: Design Tokens
description: Mercato's design tokens as Tailwind v4 @theme variables, with usage rules.
tags: [ui, design, tokens, color, typography, tailwind, theming]
timestamp: 2026-08-18T00:00:00Z
---

See [ui-guidelines.md](ui-guidelines.md) for the principles these tokens serve, [ui-components.md](ui-components.md) for how they apply to components, and [liveview-css.md](liveview-css.md) for the Tailwind pipeline conventions.

Mercato ships with a default design system, customizable at two levels:

1. **Theme config** (this file) — colors, typography, spacing, radius, and shadows are all Tailwind v4 `@theme` variables in `app.css`. Changing the look of the whole app — a rebrand, a new primary color, a different type scale — means editing values here, the same way a Bootstrap or Material UI theme config works. No component code changes.
2. **Component-level overrides** — for changes beyond what a token swap covers (a different button shape, a bespoke card layout), edit the component directly (see [ui-components.md](ui-components.md)).

Tokens are defined once in `app.css` via Tailwind v4's CSS-first `@theme`, then consumed everywhere as ordinary utility classes (`bg-primary-500`, `text-ink-700`, `rounded-btn`) — no separate token file or JS config.

## Color

The palette below is Mercato's default — a neutral, brand-agnostic starting point meant to be replaced with a marketplace's own brand colors via the same token names.

```css
@theme {
  --color-primary-050: #EFF6FF;
  --color-primary-100: #DBEAFE;   /* tints, focus ring */
  --color-primary-300: #93C5FD;
  --color-primary-500: #3B82F6;   /* primary — Brand.primary */
  --color-primary-600: #2563EB;   /* pressed; primary in dark mode */
  --color-primary-700: #1D4ED8;   /* links, small text on white (AA) */

  --color-secondary-100: #E0F2F1;
  --color-secondary-500: #0E8388; /* secondary — Brand.secondary */
  --color-secondary-600: #0B6E73;

  --color-accent-100: #FAF0D7;
  --color-accent-600: #B8860B;    /* featured / highlighted listings */

  --color-sale: #F5222D;

  --color-ink-100: #E5E5EA;     /* dividers */
  --color-ink-300: #C7C7CC;     /* soft borders */
  --color-ink-500: #8E8E93;     /* secondary text */
  --color-ink-700: #3A3A3C;     /* body text */
  --color-ink-900: #1C1C1E;     /* text, active chips */

  --color-success: #34A853;
  --color-success-text: #1E7B3F;
  --color-success-bg: #E6F4EA;
  --color-warning-text: #9A5B00;
  --color-warning-bg: #FDF0DC;
  --color-error: #E5484D;
  --color-error-text: #C0263B;
  --color-error-bg: #FDEAEA;
  --color-info-text: #1D5FA8;
  --color-info-bg: #E7F1FD;

  --color-bg: #FFFFFF;    /* page surface; cards sit on this */
  --color-bg-2: #F5F5F5;  /* secondary surface — page background behind a white card, non-critical fills */
}
```

### Usage rules

| Do | Avoid |
|---|---|
| One `bg-primary-500` CTA per screen section | Multiple primary-colored buttons competing |
| White semibold ≥15px text on `bg-primary-500` | `text-primary-500` for small text on white — use `text-primary-700` |
| `primary-600` as primary in dark mode | `primary-500` unadjusted on dark backgrounds |
| `accent-600`/`accent-100` only for featured / highlighted / premium listings | Accent color for generic highlights |
| `sale` only for discounts | `sale` for errors — that's `error` |
| Photos on white or `bg-2` | Color behind listing photos |

### Button variant → token mapping

See [ui-components.md](ui-components.md) for the full variant list. Only variants whose color isn't already obvious from its name:

| Variant | Token |
|---|---|
| `critical` | `bg-ink-900`, white text — the one non-brand-colored variant, reserved for the highest-stakes action on a screen |
| `danger` | `bg-error`, white text (same tokens as form-field/alert error states) |
| `neutral` | `bg-ink-100`, `text-ink-700` |
| `tertiary` | transparent background, `border-primary-500`, `text-primary-700` |

## Typography

```css
@theme {
  --font-sans: 'Inter', -apple-system, 'Segoe UI', sans-serif;

  --text-caption-sm: 11px;
  --text-caption-md: 12px;
  --text-caption-lg: 13px;
  --text-body-sm: 14px;
  --text-body-md: 15px;
  --text-body-lg: 16px;
  --text-body-xl: 17px;
  --text-title-sm: 15px;
  --text-title-md: 16px;
  --text-title-lg: 18px;
  --text-h2: 22px;
  --text-h1: 28px;      /* web only */
  --text-display: 34px; /* web only */
}
```

This generates utilities directly: `font-sans`, `text-body-md`, `text-h1`, `text-display`, etc. Font weights use Tailwind's default scale (`font-normal` 400, `font-medium` 500, `font-semibold` 600, `font-bold` 700, `font-extrabold` 800) — no override needed.

| Style | Utility | Web only |
|---|---|---|
| Display | `text-display font-extrabold` | Yes |
| H1 | `text-h1 font-bold` | Yes |
| Title.large | `text-title-lg` | No |
| Title.medium | `text-title-md font-semibold` | No |
| Body | `text-body-lg` / `text-body-md` | No |
| Caption | `text-caption-md text-ink-500` | No |
| Price | `text-body-md font-bold` (was-price: `text-caption-md text-ink-500 line-through`; discount: `text-caption-md text-sale font-bold`) | No |
| ListingCard.brand | `text-caption-md font-semibold text-ink-500` | No |

## Spacing, Radius & Elevation

Tailwind's default spacing scale (`--spacing: 4px` base, so `p-1`=4px, `p-2`=8px, `p-3`=12px, `p-4`=16px, `p-6`=24px, `p-8`=32px) is the default — no override needed unless a theme config calls for a different base unit.

Radius and shadow defaults don't match design values, so `@theme` overrides them directly rather than inventing new utility names:

```css
@theme {
  --radius-sm: 4px;
  --radius-md: 8px;   /* action buttons */
  --radius-lg: 12px;  /* cards, sheets */

  --shadow-sm: 0 2px 4px rgb(0 0 0 / 0.05);   /* subtle — cards */
  --shadow-md: 0 4px 14px rgb(0 0 0 / 0.09);  /* hover, sticky bars */
  --shadow-lg: 0 12px 32px rgb(0 0 0 / 0.14); /* sheets */
}
```

`rounded-full` (Tailwind default) covers pill radius for chips, badges, and avatars — no override needed.

| Group | Utility | Notes |
|---|---|---|
| Spacing | `p-1`…`p-8` etc. | Margins: 16 mobile, 24 tablet, max `max-w-[1200px]` web |
| Radius | `rounded-sm` (4) · `rounded-md` (8, buttons) · `rounded-lg` (12) · `rounded-full` (pill) | Cards: `rounded-md`/`rounded-lg`. Sheets: `rounded-lg`. Chips/badges/avatars: `rounded-full` |
| Borders | `border` (1px, standard) · `border-[1.5px]` (emphasis) | Inputs and selected states use the 1.5px border |
| Shadows | `shadow-sm` (subtle) · `shadow-md` · `shadow-lg` | subtle on cards, md on hover/sticky bars, lg on sheets |
