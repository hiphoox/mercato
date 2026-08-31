---
type: index
title: Guides
description: Map of docs/guides/ — step-by-step how-tos and runbooks.
tags: [guides, index]
timestamp: 2026-08-31T00:00:00Z
---

Map of `docs/guides/`. Each file is a step-by-step procedure for a task performed occasionally, not code documentation — see [architecture/](../architecture/index.md) for how the system is built and [explore/](../explore/index.md) for research on capabilities not yet implemented.

- [fly-provisioning.md](fly-provisioning.md) — Step-by-step runbook for creating a Fly.io app, database, storage, and secrets. Read it when standing up a new environment.
- [storage-adapters.md](storage-adapters.md) — How to add a new `Mercato.Ports.Storage` adapter (e.g. Tigris/S3) alongside the local-disk default. Read it when implementing a new storage provider.
- [browse-filters.md](browse-filters.md) — How to change which filters the browse grid offers, by declaring facets in configuration. Read it when adding, removing, or reordering a filter on browse.
- [search-engine-port.md](search-engine-port.md) — How a search engine will be added behind a port, and what is already settled about the boundary. Work in progress; read it before designing anything that touches free-text search.
- [customizing-ui.md](customizing-ui.md) — How to rebrand or restyle a marketplace built on Mercato: theme tokens, shared components, feature-specific components. Read it when forking Mercato for a new marketplace's look and feel.
