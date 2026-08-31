---
type: guide
title: Browse Filters
description: How to change which filters the browse grid offers, by declaring facets in configuration.
tags: [guide, discovery, filters, facets, configuration]
timestamp: 2026-08-31T00:00:00Z
---

The browse grid is narrowed by **facets**, declared in configuration rather than written into the page. One declaration produces the query filter, the control on the filter bar, the section in the all-filters sheet, the chip that says the facet is in force, and the query-string parameter that makes the narrowed grid a shareable address.

Adding a filter is therefore a list entry, not an edit to the read action, the bar, the sheet, the chips and the address.

## Declaring the set

Set `:browse_facets` in `config/config.exs`. Omitting the key entirely gives the default set — category, price and condition.

```elixir
config :mercato, :browse_facets, [
  [
    key: :category,
    kind: :select,
    field: {[:category], :slug},
    label: "Category",
    options: {Mercato.Listings, :category_options, []}
  ],
  [
    key: :price,
    kind: :range,
    field: :price,
    label: "Price",
    parse: {Mercato.Money, :to_minor, []},
    format: {Mercato.Money, :amount, []}
  ]
]
```

The facets are offered in the order declared. An empty list gives a grid that is searched and sorted but not narrowed.

## What a declaration says

| Key | Required | Meaning |
| :--- | :--- | :--- |
| `key` | yes | Names the facet, and names its query-string parameter. A range takes two parameters, `<key>_min` and `<key>_max`. |
| `kind` | yes | `:select` for one value chosen from a list, `:range` for a numeric span with either end open. |
| `field` | yes | What the facet narrows: an attribute name, or `{[:relationship], :attribute}` to reach across a relationship. |
| `label` | yes | What the facet is called. |
| `options` | for `:select` | A `{module, function, args}` returning `[{value, wording}]`. |
| `parse` | no | A `{module, function, args}` taking the typed string and returning `{:ok, value}` or an error, for when what a buyer types differs from what the column stores. Defaults to whole numbers for a range and to the string itself for a select. |
| `format` | no | The reverse of `parse`, used to write the value back into the address and the input. |
| `placement` | no | `:bar` (default) puts a control on the filter bar; `:sheet` keeps it to the all-filters sheet. Every facet appears in the sheet either way. |

A declaration naming a kind or a placement that does not exist raises when the facets are read, so a mistake surfaces at startup rather than as an empty grid.

## Adding one

A vehicle marketplace adding a year filter declares it and adds the attribute the facet narrows:

```elixir
config :mercato, :browse_facets, [
  # ...the facets already offered...
  [key: :year, kind: :range, field: :year, label: "Year", placement: :sheet]
]
```

Nothing in the browse page changes. The facet appears in the sheet as two number fields, states itself as `?year_min=2015&year_max=2020`, and shows a chip reading `From 2015` while it is in force.

A facet narrowing by a list of values needs a function returning that list:

```elixir
[
  key: :brand,
  kind: :select,
  field: {[:brand], :slug},
  label: "Brand",
  options: {MyMarketplace.Catalog, :brand_options, []}
]
```

## How a facet is worded

Wording splits along the copy boundary described in [i18n-copy.md](../architecture/i18n-copy.md):

- A facet this codebase ships — category, price, condition — is worded in the web layer, so its label is translatable.
- A facet a marketplace declares for itself is worded by whoever declared it, and is rendered exactly as configured. Translating it would overwrite the operator's own words.

The same holds for the values: a category name and a condition are operator data, shown as they come back from `options`.

## What is left out on purpose

**The free-text term is not a facet.** A term is matched and ranked, which belongs to the search engine rather than to the operator's choice of filters. Keeping the two apart is what lets the engine be swapped without changing which filters a buyer sees — see [search-engine-port.md](search-engine-port.md).

**The sort order is not a facet.** It states how the shelf is read rather than what is on it, which is why clearing the filters leaves the order alone.

## Behaviour worth knowing

- A value a facet does not offer — a category dropped from the catalog, a condition an instance stopped configuring — is read as no narrowing at all, so a stale or hand-typed address browses everything rather than nothing.
- A bound that is not a number is no bound.
- A select facet whose `options` come back empty draws nothing, in the bar or the sheet. An instance selling services configures no conditions and gets no condition control.
- Changing any facet returns to the first page.

## Checklist

1. Declare the facet in `:browse_facets`.
2. Give a `:select` facet an `options` function returning `[{value, wording}]`.
3. Give the facet a `parse`/`format` pair if what a buyer types is not what the column stores.
4. Confirm the attribute or relationship named by `field` exists on the listing.
5. Restart, and check the facet appears in the sheet, states itself in the address, and shows a chip while in force.
