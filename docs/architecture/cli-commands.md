---
type: architecture
title: Deterministic CLI Commands
description: Mix/CLI commands that deterministically perform a task instead of doing it manually.
tags: [architecture, cli, mix, generators, tooling]
timestamp: 2026-08-14T00:00:00Z
---

Commands in this list produce a deterministic, correct result for their task. Use the command instead of doing the task by hand (writing the resource file manually, editing the db by hand, etc.). When a new one is found or used, add it here.

## Database

- `mix ash.migrate` — run migrations.
- `mix ecto.setup` — create + migrate + seed, in one step (if defined in `mix.exs` aliases).
- `mix ash.reset` — drop and recreate the database from scratch (migrations + seeds).
- `mix run priv/repo/seeds.exs` — run the seed script directly.

## Resources

- `mix ash.gen.resource Mercato.<Domain>.<Resource> --extend sqlite` — scaffold a new Ash resource wired to the SQLite data layer.

## Codegen / snapshots

- `mix ash.codegen <name>` — generate a migration from Ash resource changes.
- `mix ash.extend <Resource> graphql` — generate a GraphQL schema from an Ash resource.
- `mix ash.extend <Resource> json_api` — generate a JSON API schema from an Ash resource.

## Setup & lifecycle (mix.exs aliases)

- `mix setup` — full project setup: `deps.get`, `ecto.setup`, `assets.setup`, `assets.build`.
- `mix assets.setup` — install Tailwind/esbuild if missing.
- `mix assets.build` — compile + build Tailwind/esbuild assets.
- `mix assets.deploy` — minified Tailwind/esbuild build + `phx.digest`, for release builds.

## Quality & CI (mix.exs aliases, mirrored in `.github/workflows/ci.yml`)

- `mix precommit` — `compile --warnings-as-errors`, `deps.unlock --unused`, `format`, `test`. Run before committing.
- `mix quality` — `compile --warnings-as-errors`, `format --check-formatted`, `credo --strict`. Matches CI's check/format/static-analysis steps.
- `mix test` — run the test suite (CI also runs this standalone).
