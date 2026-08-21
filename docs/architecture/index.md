---
type: index
title: Architecture Docs
description: Map of docs/architecture/.
tags: [architecture, index]
timestamp: 2026-08-21T00:00:00Z
---

Map of `docs/architecture/`. Open a file only when its concern is relevant — none of these are loaded by default.

## The system's shape

- [architecture.md](architecture.md) — Logical layers (Web/Core/Data/Infra) + dependency flow. Read it when orienting yourself or deciding where code belongs.
- [principles.md](principles.md) — SOLID applied to Elixir/Ash, with code examples. Read it when designing or writing a resource, boundary, or action.
- [ash-declarative-conventions.md](ash-declarative-conventions.md) — When to reach for Ash's built-in DSL (`accept`, builtin changes/validations/checks) over custom modules. Read it when writing or reviewing an Ash action, change, validation, or policy.
- [ports.md](ports.md) — The `Mercato.Ports` namespace: behaviour-plus-adapter pattern for swappable external-service boundaries (storage, and future payments/search). Read it when adding a new boundary module or a new adapter to an existing one.
- [data-architecture.md](data-architecture.md) — SQLite, AshSqlite, migrations, soft-delete, audit log, backups. Read it when touching persistence, schema, or data retention.
- [seeds.md](seeds.md) — How seed data is organised across `priv/repo/seeds/` and what belongs in it. Read it when adding or changing seed data.
- [data-layer-expressions.md](data-layer-expressions.md) — Where SQLite's filter expression support diverges from Postgres, and how that divergence is contained. Read it when writing a filter expression, or when a search returns wrong or no rows.
- [security.md](security.md) — Authentication and authorization model. Read it when working on auth, sessions, tokens, or permissions.

## Standards & process

- [coding-standards.md](coding-standards.md) — Elixir, Mix, and Phoenix (backend) conventions. Read it when writing any Elixir/Phoenix code.
- [liveview.md](liveview.md) — LiveView module conventions: layouts, scope, component structure. Read it when writing a LiveView module.
- [heex-templates.md](heex-templates.md) — HEEx template syntax. Read it when writing a HEEx template.
- [liveview-streams.md](liveview-streams.md) — Using LiveView streams for collections. Read it when about to use streams for a collection.
- [liveview-css.md](liveview-css.md) — Tailwind/CSS asset pipeline. Read it when writing CSS or touching the asset pipeline.
- [liveview-js.md](liveview-js.md) — LiveView JS interop: hooks, push_event. Read it when writing a JS hook or client/server event.
- [ui-guidelines.md](ui-guidelines.md) — Guiding principles for the design system. Read it when starting any UI/design work.
- [design-tokens.md](design-tokens.md) — Color, typography, and spacing/radius tokens, with code mapping. Read it when styling a component or picking a color/type value.
- [responsive-layout.md](responsive-layout.md) — Breakpoint regimes for the app layout, sidebar drawer/rail state, and header wrapping. Read it when building a layout that adapts across widths, or touching the sidebar's collapse state.
- [ui-components.md](ui-components.md) — Specs for buttons, form fields, badges, chips, tables, listing card, and nav bar. Read it when building or reviewing a UI component.
- [commerce-ux-patterns.md](commerce-ux-patterns.md) — Discovery, trust signals, cart/checkout, optional offer negotiation, order tracking, sell flow, and notification/feedback patterns. Read it when building browsing, purchase, offer, selling, order-status, or notification UI.
- [accessibility-dark-mode.md](accessibility-dark-mode.md) — Accessibility rules and dark mode token overrides. Read it when checking contrast, focus states, or dark mode.
- [testing.md](testing.md) — Backend and Ash test conventions. Read it when writing backend/Ash tests.
- [liveview-testing.md](liveview-testing.md) — LiveView test conventions. Read it when writing LiveView tests.
- [git-strategy.md](git-strategy.md) — Branching model, release workflow, versioning. Read it when branching, releasing, or versioning.
- [cli-commands.md](cli-commands.md) — Deterministic Mix/CLI commands for tasks like db setup, migrations, seeding, resource generation. Read it before doing a task by hand that a command might already do.
- [ci-pipeline.md](ci-pipeline.md) — Quality gates, CI commands, verification. Read it when setting up or debugging CI.
- [cd-pipeline.md](cd-pipeline.md) — Deploy workflow, triggers, and environments. Read it when setting up or debugging deployment automation.
- [infrastructure-and-deployment.md](infrastructure-and-deployment.md) — Compute specs, persistence, backups, deploy. Read it when deploying or changing infrastructure.

Step-by-step guides and runbooks live in [docs/guides/](../guides/index.md).
