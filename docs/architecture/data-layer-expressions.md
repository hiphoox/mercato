---
type: architecture
title: Data Layer Expressions
description: Where SQLite's filter expression support diverges from what a filter needs, and how that divergence is contained.
tags: [architecture, ash, sqlite, filters, portability]
timestamp: 2026-08-20T00:00:00Z
---

Filters are written as declarations of intent — "a case-insensitive substring match" — and the data layer decides how to spell that in SQL. SQLite compiles a narrower set of expressions than Postgres does, so some intents need a different expression here than they would elsewhere.

That difference is contained in a custom expression with one clause per data layer, registered once for the application. A resource names the intent; the expression supplies each backend's spelling. Swapping the data layer changes the expression, not the actions that use it.

## Known divergences

**Case-insensitive matching.** SQLite has no `ILIKE`, and its substring function is case-sensitive. A case-insensitive match downcases both operands explicitly. A case-insensitive string type carries no case-insensitivity into a SQLite comparison the way it does into a Postgres one.

**Substring matching against a literal.** The built-in `contains` compiles, when its second operand is a literal, to a `LIKE` pattern with `_` and `%` backslash-escaped and no `ESCAPE` clause. SQLite ignores an unbacked escape character, so the escape sequence is matched literally and the comparison finds nothing. Any value that can contain `_` or `%` — a handle, a slug, a filename — is affected. The substring-position function has no such path.

**String concatenation across columns.** Joining several columns into one searchable value is not compilable to SQLite at all and is rejected when the query runs. A search across several columns is a disjunction over those columns.

## Recognising a divergence

Two failure modes, and only one of them announces itself:

| Symptom | Cause |
|---|---|
| The query raises when it runs | The data layer cannot compile the expression at all |
| The query succeeds and returns wrong rows | The expression compiled to SQL that means something else here |

The silent one is the reason a search filter is covered by a test whose data actually triggers it — a value containing an underscore, a query differing from the stored value only in case. A search test using only plain lowercase ASCII passes against a filter that is broken for real data.

Before assuming an expression works, check that the data layer declares it compilable; an expression absent from that list fails at query time rather than at compile time.
