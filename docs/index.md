---
type: index
title: Docs
description: Registry of docs/ sections — the entry point for finding which section owns a concern.
tags: [index]
timestamp: 2026-07-23T00:00:00Z
---

Registry of `docs/` sections. Each section has its own `index.md` mapping its files — open the section index for the concern, then the file it points to.

`docs/` has four fixed sections:

- [architecture/](architecture/index.md) — System shape and all backend/frontend/testing/CI/process standards.
- [domain/](domain/index.md) — Entities, their business rules, and ER diagrams.
- [explore/](explore/index.md) — Research, decisions, and per-area backlogs for capabilities not yet implemented (library choices, integration approaches, what is left to build). Check here before researching something from scratch; a file moves out to the section it belongs to once the thing is actually built.
- [guides/](guides/index.md) — Step-by-step how-tos and runbooks (e.g. provisioning an environment, adding a new adapter to an existing port).

This is a closed set. A new top-level section is a structural decision, not a documentation one — ask the user before creating one.
