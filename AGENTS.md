# Mercato - Project Guide

## 📌 Project Overview

Mercato is a general-purpose marketplace based primarily on the C2C model; it is designed to be infrastructure-less as much as possible and serve as a foundation for building any marketplace on top of it.

**IMPORTANT: Rule of thumb — infra-less as much as possible:** no separate database server, no required external services beyond the app itself. External providers (object storage, payments, shipping) as opt-in, swappable adapters rather than hard dependencies. When adding a new integration or persistence need, prefer a local/in-app default with an external provider as a pluggable option, not the other way around.

## 🛠 Tech Stack

- **Core:** Elixir v1.20, Erlang/OTP 29, Phoenix 1.8.7, Ash Framework.
- **UI:** LiveView, Tailwind CSS 4.x.
- **Data:** SQLite
- **Infrastructure:** It is opt-in.
- **Integrations (defaults, swappable):** Stripe + Stripe Connect (payments & seller payouts), Shippo (multi-carrier shipping API).

## 🗺️ Documentation

This project uses a distributed documentation model: one source of truth per concern, indexed for on-demand reading rather than upfront loading. Start at [docs/index.md](docs/index.md) — it maps every section (`docs/architecture/`, `docs/domain/`, `docs/explore/`, …), and each section's own `index.md` maps its files. See the `read-docs` and `write-docs` skills for the discovery/authoring procedure.

Before researching or designing an approach for something that doesn't exist in the codebase yet (a new library, integration, or capability), check [docs/explore/index.md](docs/explore/index.md) first — the exploration may already be done. `docs/explore/` holds decisions/research for not-yet-built capabilities; once built, the file graduates to the section that owns it (usually `docs/architecture/`) and is reconciled to match the real code.

## 🤖 Agent Skills IMPORTANT

- **`working-on-changes`** — **MANDATORY prerequisite.** Invoke this before and during any task that changes code, schema, or docs: ask clarifying questions, read docs/code first, propose a plan, implement with TDD, run the full suite, and always ask explicit permission before committing.
- **`read-docs`** — **MANDATORY prerequisite.** Invoke this BEFORE any other skill (including brainstorming) and before writing, editing, or reviewing any code, schema, or docs in this repo. Find and read the specific `docs/` files that govern the task, and only those. `docs/architecture/` often already contains the authoritative spec for a task (e.g. CI, testing, deployment) — check there before treating something as an open design question.
- **`write-docs`** — Create, edit, convert, or split `docs/` files per the OKF convention (frontmatter, one concern per file, discoverable index).
- **`understand-code`** — **MANDATORY prerequisite.** Invoke this before implementing, changing, debugging, or reviewing code in this repo — before any Grep/Read-based exploration and before answering questions about existing functions, callers, or structure, even a single lookup you think you already know. Uses the `codebase-memory-mcp` knowledge graph for structural queries (callers, call chains, definitions); falls back to Grep/Read with a one-time warning if the MCP isn't installed.
- **`deterministic-commands`** — **MANDATORY prerequisite.** Invoke this before doing any task manually that a CLI/Mix command could do deterministically instead. Checks `docs/architecture/cli-commands.md` for a matching command first, and keeps that list current.
- **`answering-questions`** — Invoke when the user asks a conceptual question or doubt rather than requesting an implementation change. Answers lead directly with the answer, formatted as short bullets, no preamble or trailing summary.
