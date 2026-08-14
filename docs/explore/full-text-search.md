---
type: explore
title: Full-Text Search
description: How to implement full-text search on SQLite via FTS5.
tags: [explore, sqlite, fts5, search]
timestamp: 2026-08-14T00:00:00Z
---

Mercato has no full-text search implemented yet. When it is, it uses SQLite's **FTS5** virtual table module — no extra install or config needed, since `exqlite` (the driver behind `ecto_sqlite3`/`ash_sqlite`) compiles SQLite with `-DSQLITE_ENABLE_FTS5=1` by default.

## Why FTS5 Fits

FTS5 is built into the SQLite binary `exqlite` already ships, so it needs no separate service or extension — consistent with the infra-less/SQLite-only rule of thumb (see [data-architecture.md](../architecture/data-architecture.md)).

## How It's Wired

FTS5 tables are SQLite virtual tables, which neither Ecto nor Ash generates natively. The integration is manual:

- **Migration:** create the virtual table with raw SQL via `execute/2` (Ecto SQL has no virtual-table DSL):
  ```elixir
  execute("""
    CREATE VIRTUAL TABLE documents USING fts5(
      updated_at UNINDEXED,
      inserted_at UNINDEXED,
      title,
      author,
      body
    );
    """, "DROP TABLE documents;")
  ```
  Columns marked `UNINDEXED` are stored but not searched; FTS5 indexes the rest and provides a built-in `rowid`.

- **Schema:** map `rowid` to the primary key and add a virtual `rank` field for relevance scoring:
  ```elixir
  @primary_key {:id, :id, autogenerate: true, source: :rowid}
  field :rank, :float, virtual: true
  ```

- **Query:** use the `MATCH` operator via `fragment/2`, ordered by `rank` — this bypasses Ash's normal query DSL and runs as a raw `Ecto.Query` fragment from within a resource action or custom read:
  ```elixir
  from(d in Document,
    select: [:title, :url, :rank, :id],
    where: fragment("documents MATCH ?", ^q),
    order_by: [asc: :rank]
  )
  |> Repo.all()
  ```

## Reference

- [SQLite3 Full-Text Search with Phoenix](https://fly.io/phoenix-files/sqlite3-full-text-search-with-phoenix/) — full walkthrough this pattern is based on.
- [exqlite Makefile](https://github.com/elixir-sqlite/exqlite/blob/main/Makefile) — confirms `SQLITE_ENABLE_FTS5` is compiled in.
