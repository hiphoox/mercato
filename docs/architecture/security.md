---
type: architecture
title: Security
description: Authentication and authorization model.
tags: [architecture, security, auth, rbac]
timestamp: 2026-08-21T00:00:00Z
---

Mercato is a single-tenant C2C marketplace with authentication and authorization on the `users` entity. See the [ER diagram](../domain/users/er-diagram.md) for `users`, `roles`, `permissions`, `role_permissions`, and `user_roles`; see [users/index.md](../domain/users/index.md) for the full set of users domain docs, including roles and account-status business rules.

## Authentication

Users sign in with email + password or a magic link sent to their email. An account may have no password set (magic-link-only accounts).

- **Web:** session-based cookie authentication.
- **Mobile:** API tokens / JWTs.
- Sign-in is rejected for account statuses that block authentication (see Account Status below).
- A banned or deleted account fails sign-in the same way wrong credentials would — the response doesn't reveal that the account exists.

## Authorization

**RBAC:** users → roles → permissions, with `role_permissions` as the data-driven grant between a role and a permission — adding a role or grant doesn't require a schema change.

**v1:** every user holds exactly one role, seeded with `trader` (default — buy + sell) and `admin` (platform staff), enforced at the application layer rather than the schema. There is no in-session active-role switching in v1; a user's single role applies for the life of the session.

**Admin area:** reaching any admin page requires the `admin:access` permission, seeded onto the `admin` role. The permission gates both the page and the data behind it, so a user without it is refused the listing itself, not merely redirected away from the URL.

**Access rules on a user's own record:**
- Anyone can read a user's public profile fields (name, handle, avatar, email, status) — e.g. a buyer viewing a seller's profile on a product page.
- A user can update their own record; an `admin` can update any user's record.
- Changing a user's status is `admin`-only — a user cannot change their own status, even though they can otherwise update their own record.
- Deleting an account requires either that it is the actor's own account or that the actor holds the `user:delete` permission, seeded onto the `admin` role. Deletion is terminal and erases the account, so it carries its own permission rather than riding on the one that governs ordinary updates — see [account-deletion.md](../domain/users/account-deletion.md).

## Account Status

`status` (`active | restricted | banned | deleted`) gates authentication independent of role. A banned or deleted user cannot sign in through any authentication method (password, short-lived token exchange, or magic link), even with valid credentials. A deleted account is refused twice over: it is archived, and an archived account is filtered out of every authenticating read, so a session held from before deletion stops resolving to a user. An active or restricted user can — a restriction limits what the person may do once inside, not whether they hold a session.
