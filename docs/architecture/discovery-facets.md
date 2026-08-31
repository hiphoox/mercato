---
type: architecture
title: Discovery Facets
description: How the browse grid's filters and orders are declared once and drive both the query and the controls.
tags: [architecture, discovery, filters, facets, browse]
timestamp: 2026-08-31T12:00:00Z
---

The browse grid is narrowed by facets that are declared as configuration. One declaration is the single source for the filter applied to the read, the control drawn on the bar, the section in the all-filters sheet, the chip stating the facet is in force, and the query-string parameter that makes a narrowed grid a shareable address.

A marketplace changes what its grid can be narrowed by without editing the read, the page, or any markup. The declaration says what a facet narrows, how it narrows, and where it draws; nothing else knows which facets exist.

## What a facet declares

A facet has a key, a kind, the field it narrows, and a label. A select facet also has a source for the values it offers. A facet may state how to read a typed value and how to write it back, which is what lets a price be typed in the units on the price tag and compared in the units it is stored in.

Two kinds are narrowed by: one value chosen from a list, and a numeric range with either end open. A third kind is added by extending the vocabulary, not by changing the two that exist.

The field a facet narrows may sit on the listing or across a relationship.

## The order of narrowing

The term and the facets are applied separately. A term is matched across a listing's title and description; the facets are applied on top of it, one filter per facet in force. A facet left unstated narrows nothing.

Facets are stated in the query string, so a narrowed grid can be linked, shared and reloaded. A facet that is not narrowing anything leaves no parameter behind, which is what gives the whole shelf a single address. Changing any facet returns to the first page.

## Forgiveness

Everything unusable is dropped rather than refused, so a stale or hand-typed address lands on the grid:

| Stated | Read as |
| :--- | :--- |
| A parameter no facet claims | no narrowing |
| A value stated as empty | no narrowing |
| A range bound that is not a number | that end left open |
| A value the facet does not offer — a category the catalog dropped, a condition no longer configured | no narrowing |
| A facet kind or placement that does not exist | a failure when the facets are read, at startup |

The last row is deliberately not forgiving. A misdeclared facet is an operator's mistake, and failing at startup is what stops it from surfacing as a grid that silently narrows by nothing.

## What is not a facet

**The free-text term.** A term is matched and ranked, which is the search engine's concern rather than the operator's choice of what to offer. Keeping it out of the facet set is what lets the engine change without changing which filters a buyer sees.

**The sort order.** It states how the shelf is read rather than what is on it, which is why clearing the filters leaves the order standing. It is declared all the same, and separately — see below.

## Orders

The orders the grid can be read in are declared the same way the facets are, and for the same reason: a vehicle marketplace offers fewest miles and a rentals one soonest available, neither of which the grid should have to be edited to say.

A declaration names the order's key, what it is called, and the columns its own order turns on. It does not name what settles two rows that tie on those columns, because that is supplied:

**Every order is read as its own columns followed by the default order's.** Two listings at the same price would otherwise come back in whatever order the data layer happened to produce, and a grid that reshuffles between two identical reads reads as a bug rather than as a tie. Supplying it rather than declaring it means a marketplace adding an order cannot forget what it never had to write.

**The default order is the first one declared.** A marketplace states its default by putting it first rather than by naming it twice, and that order is the absence of the parameter in the address, so the plain shelf keeps one address.

Where a facet is forgiving, an order is not: a read asked for an order nobody offers is refused rather than quietly given the default. A facet is forgiving because a stale address should still land on the grid; an order is not a narrowing, so the browse page settles an unreadable one into the default before the read ever sees it, and a read asked directly for a bad order has been given a caller's mistake rather than a buyer's stale link.

## How a facet is drawn

The bar and the sheet draw the same facet differently, because they hold different numbers of them. The bar shows one facet at a time in a panel over the grid, so its values are a list picked down. The sheet stacks every facet at once, so each is a single row: a marketplace declaring ten facets would otherwise scroll past nine lists to reach the tenth.

A facet may ask to stay out of the bar. Every facet appears in the sheet regardless, so the same narrowing is reachable at every width.

A select facet with no values to offer draws nothing at all. An instance selling services configures no conditions, and a control with an empty list reads as a page that failed to load rather than as a facet that does not apply.

While a facet is narrowing the grid it is named by a chip, which removes it when clicked. A range is stated by typing and submitted on its own, since half a range is a bound the buyer has not finished writing.

## Wording

Wording follows the copy boundary in [i18n-copy.md](i18n-copy.md). A facet or an order this codebase ships is worded in the web layer, one clause apiece returning a literal, so a translator can find it. One a marketplace declared for itself is worded by the operator and rendered as configured, as are the values a facet offers — a category name and a condition are operator data, not source text.

## Related

- [browse-filters.md](../guides/browse-filters.md) — the procedure for declaring a facet set.
- [search-engine-port.md](../guides/search-engine-port.md) — the boundary the term will move behind, and why the facets are separate from it.
- [commerce-ux-patterns.md](commerce-ux-patterns.md) — how discovery should behave on screen.
