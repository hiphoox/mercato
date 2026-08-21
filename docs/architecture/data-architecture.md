---
type: architecture
title: Data Architecture
description: SQLite data architecture baselines.
tags: [architecture, sqlite, data]
timestamp: 2026-08-21T00:00:00Z
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

User deletion is a **soft delete with anonymization**, never a hard delete. The row survives, stamped with the time it was archived, holding nothing that identifies its former owner.

- Personal data is cleared, the email is replaced with an opaque placeholder, and the stored avatar image is removed from object storage.
- An archived account is filtered out of every read except the admin users dashboard, which keeps the row to show that an account was there.
- Transactional history, reviews, and sold products are retained for accounting, tax compliance, and dispute resolution.
- Products removed by moderation keep an internal backup.

See [account-deletion.md](../domain/users/account-deletion.md) for the full rules and the two flows that trigger deletion.

## 4. Audit Log

Sensitive admin edits are recorded in an audit log capturing **who changed what and when**.

- Covers seller earnings, user emails, and bank account details edited from the admin dashboard.
- Provides accountability for manual interventions outside the normal automated flows.

## 5. Backups & Object Storage

- The database is a **SQLite file on a Fly.io persistent volume**, with scheduled backups — no separate database server to provision or operate.
- Large assets (product images) are **not** stored in SQLite — they live in object storage (**Tigris**), with the database holding references (URLs/keys).
