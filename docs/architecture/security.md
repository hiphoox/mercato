---
type: architecture
title: Security
description: Authentication and authorization model.
tags: [architecture, security, auth, rbac]
timestamp: 2026-08-17T00:00:00Z
---

Mercato is a single-tenant C2C marketplace. Authentication and authorization are implemented with **ash_authentication** on the `users` resource. See the [ER diagram](../domain/users/er-diagram.md) for `users`, `roles`, `permissions`, `role_permissions`, and `user_roles`; see [users/index.md](../domain/users/index.md) for the full set of users domain docs, including roles and account-status business rules.

## Authentication

Email + password (`ash_authentication`'s `Password` strategy) and magic link. `hashed_password` and `confirmed_at` (email-confirmation add-on) live directly on `users`; `hashed_password` is nilable, since the magic-link strategy creates accounts with no password set.

- **Web:** session-based cookie authentication.
- **Mobile:** API tokens / JWTs.
- Sign-in is rejected for account statuses that block authentication (see [users/index.md](../domain/users/index.md)).

## Authorization

**RBAC:** `users` → `user_roles` → `roles` → `role_permissions` → `permissions`. `permissions` is data-driven, so each role is a `roles` row with its own `role_permissions` grants — adding a role or grant doesn't require a schema change.

**v1:** every user holds exactly one role via `user_roles`, seeded with `trader` (default — buy + sell) and `admin` (platform staff), enforced at the application/policy layer rather than the schema. There is no in-session active-role switching in v1; a user's single role applies for the life of the session.

## Account Status

`users.status` gates authentication and available actions, independent of role. Implemented as a plain `status` attribute (`active | banned | deleted`) with Ash policies gating actions per state.
