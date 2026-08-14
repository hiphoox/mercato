---
type: index
title: Explore Docs
description: Map of docs/explore/ — research and decisions for capabilities not yet implemented.
tags: [explore, index]
timestamp: 2026-08-14T00:00:00Z
---

Map of `docs/explore/`. Each file documents a decision or research finding for something the project doesn't have yet — a library choice, an integration approach, a constraint discovered ahead of implementation. Once the thing is actually built, its file moves to the section that owns it (usually `architecture/`) and is reconciled to match the real code, per `write-docs`.

**Before researching or designing a solution for something that doesn't exist in the codebase yet, check here first** — the exploration may already be done.

- [analytics-duckdb.md](analytics-duckdb.md) — Analytics via embedded DuckDB (`duckdbex`), backed by Ash manual actions since there's no `ash_duckdb`.
- [background-jobs.md](background-jobs.md) — Background/scheduled job processing baseline (Oban core, not `ash_oban`) and its SQLite constraint.
- [full-text-search.md](full-text-search.md) — Full-text search via SQLite FTS5: virtual table migration, schema, and query pattern.
