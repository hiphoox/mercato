---
type: architecture
title: Data Layer Expressions
description: Where SQLite's filter expression and query-feature support diverges from what a filter needs, and how that divergence is contained.
tags: [architecture, ash, sqlite, filters, portability]
timestamp: 2026-08-20T00:00:00Z
---

Filters are written as declarations of intent — "a case-insensitive substring match" — and the data layer decides how to spell that in SQL. SQLite compiles a narrower set of expressions than Postgres does, so some intents need a different expression here than they would elsewhere.

That difference is contained in a custom expression with one clause per data layer, registered once for the application. A resource names the intent; the expression supplies each backend's spelling. Swapping the data layer changes the expression, not the actions that use it.

## Known divergences

**Case-insensitive matching.** SQLite has no `ILIKE`, and its substring function is case-sensitive. A case-insensitive match downcases both operands explicitly. A case-insensitive string type carries no case-insensitivity into a SQLite comparison the way it does into a Postgres one.

**Substring matching against a literal.** The built-in `contains` compiles, when its second operand is a literal, to a `LIKE` pattern with `_` and `%` backslash-escaped and no `ESCAPE` clause. SQLite ignores an unbacked escape character, so the escape sequence is matched literally and the comparison finds nothing. Any value that can contain `_` or `%` — a handle, a slug, a filename — is affected. The substring-position function has no such path.

**String concatenation across columns.** Joining several columns into one searchable value is not compilable to SQLite at all and is rejected when the query runs. A search across several columns is a disjunction over those columns.

## Unsupported query features

Beyond individual expressions, AshSqlite declines whole categories of query feature that AshPostgres supports. `can?/2` in `AshSqlite.DataLayer` is the authoritative list; check it before designing around a feature rather than discovering the gap at runtime.

The consequential ones:

| Feature | Supported | Consequence |
|---|---|---|
| `aggregates do ... end` on a resource | **No** | No `count`, `list`, `first`, `sum` aggregates. Aggregate filtering, sorting, and aggregates across a relationship are all refused too. |
| Transactions | **No** | A multi-write action cannot be rolled back as a unit; a failure partway leaves the earlier writes in place. |
| Lateral joins | **No** | — |
| `distinct` / distinct sort | **No** | A join that can duplicate rows cannot be de-duplicated in the query. |
| Expression calculations, and sorting on them | **Yes** | The substitute for a simple derived value. |
| `exists/2`, filter expressions, nested expressions, filtering across a relationship | **Yes** | The substitute for an aggregate in a *boolean* test. |
| Query-time counts (`Ash.count/2`, `page: [count: true]`) | **Yes** | The substitute for a `count` aggregate when a number is needed. |

**The absent aggregates are the constraint most likely to redirect a design.** A rule phrased as "does this record relate to something matching X" is expressible — as `exists/2` in a filter or an expression calculation. A rule needing the related values *collected* — a list of names, a count folded into a policy — is not, and needs a different shape: a query-time count, or a custom check module that runs its own read.

That last case is why an actor-side permission check on this project is a custom `Ash.Policy.SimpleCheck` rather than an `aggregate list :permission_names` plus `authorize_if expr(...)`. The declarative form is unavailable here, not merely unchosen. See [ash-declarative-conventions.md](ash-declarative-conventions.md) for when a custom module is warranted.

## Recognising a divergence

Two failure modes, and only one of them announces itself:

| Symptom | Cause |
|---|---|
| The query raises when it runs | The data layer cannot compile the expression at all |
| The query succeeds and returns wrong rows | The expression compiled to SQL that means something else here |

The silent one is the reason a search filter is covered by a test whose data actually triggers it — a value containing an underscore, a query differing from the stored value only in case. A search test using only plain lowercase ASCII passes against a filter that is broken for real data.

Before assuming an expression works, check that the data layer declares it compilable; an expression absent from that list fails at query time rather than at compile time. The same applies to a query feature — an unsupported one surfaces when the query runs, not when the resource compiles.
