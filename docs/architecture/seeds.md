---
type: architecture
title: Seeds
description: How seed data is organised and what belongs in it.
tags: [architecture, data, seeds, database]
timestamp: 2026-08-31T00:00:00Z
---

Seed data is the baseline records a fresh database needs before anyone signs in — the roles and permissions the authorization model is built on, and the reference catalogs features look up by name.

## Layout

- `priv/repo/seeds.exs` is the single entry point. It contains no seed data itself; it lists the concern files and the order they run in.
- `priv/repo/seeds/<concern>.exs` holds the data for one concern. Today that is `accounts.exs` — roles, permissions, the grants between them, and sample traders — and `listings.exs` — the category catalog, and a stock of listings for those traders to have on offer.

A new concern gets its own file and one added line in the entry point. When a concern depends on another's records — a listing needing a seller — the dependency is expressed by ordering the list, and the dependent file looks its prerequisites up rather than receiving them.

Adding a file without listing it in the entry point means it never runs; nothing globs the directory.

## What belongs in a concern file

- Data the application requires to function at all, in every environment.
- Sample data for local development, guarded so it is skipped outside dev.

Both live in the same concern file. The environment guard is what separates them, so one file still answers "what does this concern seed?".

## Running

Seeds run as part of database setup and reset — see [cli-commands.md](cli-commands.md) for the commands. They are never run against production data as a routine step.

Only the required-in-every-environment data is safe to re-run; seeding an already-seeded database fails on the duplicate. Sample development data is skipped when it already exists — a trader who is already registered, and a trader who already has listings.

## Sample development data

Dev gets six named accounts, all with the password `password1234`: an admin, and five traders who between them have twenty described listings spread across every lifecycle state, so browsing, a seller's profile, the listing management view and the moderation view all have something in them.

Fifty numbered accounts are seeded alongside them as bulk, holding no listings, most of them active with a handful restricted or banned. They put more than one page of rows in the admin account listing, so its paging, its search and its status filter all have something to work on.

On top of those, a hundred numbered listings are seeded as bulk, all active, spread round-robin across the same five traders and every category, at random prices. They put several pages of results on the browse grid, so paging, sorting and filtering all have enough to work on.

A listing reaches its state the way a seller would reach it, so a paused one here has genuinely been published and paused. Photos are drawn rather than shipped: a flat-colour image is generated per photo and uploaded through the same gallery the app uploads with, which keeps binary files out of the repository and leaves a listing publishable. A described listing carries two photos, a numbered one carries a single photo.
