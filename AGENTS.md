# Mercato - Project Guide

## 📌 Project Overview

Mercato is a general-purpose C2C marketplace platform, built to be infrastructure-less as much as possible. Users buy and sell items through an escrow-style flow where payment is held until delivery is confirmed.

Payment, shipping, and similar third-party vendors are pluggable — the platform is designed to accept additional providers beyond the ones currently integrated.

## 🛠 Tech Stack

- **Core:** Elixir v1.20, Erlang/OTP 29, Phoenix 1.8.7, Ash Framework.
- **UI:** LiveView, Tidewave, Tailwind CSS 4.x.
- **Data:** SQLite
- **Infrastructure:** Fly.io, Tigris.
- **Integrations (defaults, swappable):** Google & Apple OAuth (social sign-in, alongside email + password), Stripe + Stripe Connect (payments & seller payouts), Shippo (multi-carrier shipping API).

## 🗺️ Documentation

This project uses a distributed documentation model: one source of truth per concern, indexed for on-demand reading rather than upfront loading. Start at [docs/index.md](docs/index.md) — it maps every section (`docs/architecture/`, `docs/domain/`, …), and each section's own `index.md` maps its files. See the `read-docs` and `write-docs` skills for the discovery/authoring procedure.

## 🤖 Agent Skills

- **`read-docs`** — **MANDATORY prerequisite.** Invoke this BEFORE any other skill (including brainstorming) and before writing, editing, or reviewing any code, schema, or docs in this repo. Find and read the specific `docs/` files that govern the task, and only those. `docs/architecture/` often already contains the authoritative spec for a task (e.g. CI, testing, deployment) — check there before treating something as an open design question.
- **`write-docs`** — Create, edit, convert, or split `docs/` files per the OKF convention (frontmatter, one concern per file, discoverable index).
- **`understand-code`** — **MANDATORY prerequisite.** Invoke this before implementing, changing, debugging, or reviewing code in this repo — before any Grep/Read-based exploration and before answering questions about existing functions, callers, or structure, even a single lookup you think you already know. Uses the `codebase-memory-mcp` knowledge graph for structural queries (callers, call chains, definitions); falls back to Grep/Read with a one-time warning if the MCP isn't installed.
