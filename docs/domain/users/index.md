---
type: index
title: Users Domain Docs
description: Map of docs/domain/users/ — domain rules and diagrams for user accounts and roles.
tags: [domain, users, index]
timestamp: 2026-08-21T00:00:00Z
---

Domain files for the `users` entity group. Open a file only when its concern is relevant.

- [users.md](users.md) — Business rules for the User entity: identity, profile fields, handle/avatar behavior, self-service profile management, account status, and role/permission model. Read it when working on user identity, profile, status, or role/permission behavior.
- [account-deletion.md](account-deletion.md) — What deleting an account erases, what it keeps, who may trigger it, and how each flow confirms. Read it when working on account deletion, anonymization, or data retention for a user.
- [er-diagram.md](er-diagram.md) — Entity-relationship diagram for `users`, `settings`, `roles`, `permissions`, `role_permissions`, and `user_roles`. Read it when modeling or querying the User/RBAC schema.
