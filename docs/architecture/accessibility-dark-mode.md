---
type: architecture
title: Accessibility & Dark Mode
description: Accessibility rules and dark mode token overrides for the UI.
tags: [ui, accessibility, dark-mode]
timestamp: 2026-08-04T00:00:00Z
---

See [design-tokens.md](design-tokens.md) for the base color tokens referenced here.

## Accessibility

| Rule | Detail |
|---|---|
| White on primary-500 | Buttons/large-bold text only (≥15px semibold) |
| Primary color on small text over white | Use primary-700, verified for AA contrast (≥4.5:1) against white |
| Touch targets | ≥44×44, ≥8px apart |
| Focus | 3px primary-100 ring, never removed |
| State signals | Icon or text accompanies every color-only signal |

## Dark Mode

| Aspect | Value |
|---|---|
| Primary | primary-600 `#2563EB` |
| Backgrounds | system colors on native; web `#1C1C1E` / `#2C2C2E` |
| Tints | Primary color at 16% opacity replaces primary-100/050 |
| Active chips | Inverted — white fill, black text |
