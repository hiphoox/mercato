---
type: architecture
title: Seeds
description: How seed data is organised and what belongs in it.
tags: [architecture, data, seeds, database]
timestamp: 2026-08-21T00:00:00Z
---

Seed data is the baseline records a fresh database needs before anyone signs in — the roles and permissions the authorization model is built on, and the reference catalogs features look up by name.

## Layout

- `priv/repo/seeds.exs` is the single entry point. It contains no seed data itself; it lists the concern files and the order they run in.
- `priv/repo/seeds/<concern>.exs` holds the data for one concern. Today that is `accounts.exs` — roles, permissions, the grants between them, and sample users.

A new concern gets its own file and one added line in the entry point. When a concern depends on another's records — a listing needing a seller — the dependency is expressed by ordering the list, and the dependent file looks its prerequisites up rather than receiving them.

Adding a file without listing it in the entry point means it never runs; nothing globs the directory.

## What belongs in a concern file

- Data the application requires to function at all, in every environment.
- Sample data for local development, guarded so it is skipped outside dev.

Both live in the same concern file. The environment guard is what separates them, so one file still answers "what does this concern seed?".

## Running

Seeds run as part of database setup and reset — see [cli-commands.md](cli-commands.md) for the commands. They are never run against production data as a routine step.

Only the required-in-every-environment data is safe to re-run; seeding an already-seeded database fails on the duplicate. Sample development users are skipped when they already exist.
