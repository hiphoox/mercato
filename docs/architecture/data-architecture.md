---
type: architecture
title: Data Architecture
description: SQLite data architecture baselines.
tags: [architecture, sqlite, data]
timestamp: 2026-07-23T00:00:00Z
---

Mercato uses a **single shared SQLite database** for the entire marketplace — all users, listings, transactions, and payouts live in one dataset and reference each other directly. SQLite keeps the platform infra-less: no separate database server to provision, operate, or pay for. (See [entities.md](../domain/entities.md) for entity definitions.)

## 1. Access via AshSqlite

All persistence is defined through `AshSqlite.DataLayer` inside each Ash resource. Resources own their table mapping, relationships, and constraints — there is no hand-written repo/query layer.

- **Zero Raw Repo:** direct `Repo` access is forbidden outside migrations; everything goes through Ash actions.

## 2. Migrations

Schema is derived from the resource definitions, not authored by hand.

- Generate migrations with `mix ash.codegen <name>` and apply them with `mix ash.migrate`.
- Resources are the source of truth; migrations are the generated artifact.

## 3. Soft Delete & Anonymization

User deletion is a **soft delete with anonymization**, never a hard delete.

- Personal data (email, phone, photo, address) is cleared and the name becomes a "Deleted user" placeholder.
- Transactional history, reviews, and sold products are retained for accounting, tax compliance, and dispute resolution.
- Products removed by moderation keep an internal backup.

## 4. Audit Log

Sensitive admin edits are recorded in an audit log capturing **who changed what and when**.

- Covers seller earnings, user emails, and bank account details edited from the admin dashboard.
- Provides accountability for manual interventions outside the normal automated flows.

## 5. Backups & Object Storage

- The database is a **SQLite file on a Fly.io persistent volume**, with scheduled backups — no separate database server to provision or operate.
- Large assets (product images) are **not** stored in SQLite — they live in object storage (**Tigris**), with the database holding references (URLs/keys).
