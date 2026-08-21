---
type: domain
title: Users
description: Business rules for the User entity — identity, profile, self-service management, account status, and role membership.
tags: [domain, users, rbac, profile, account-status]
timestamp: 2026-08-21T00:00:00Z
---

## Identity

A user's account is identified by a unique, case-insensitive email address. Not every account has a password — an account that has only ever signed in via magic link has none. Every user also has a public, unique handle (an `@username`), distinct from and independent of their email.

## Profile fields

A user's first name, last name, handle, avatar, email, and account status are visible to anyone viewing their profile. First name is required at password registration; last name is always optional. A magic-link account may hold neither name until the user sets one.

## Handle

A handle is generated silently on account creation — never a sign-up form field. It's slugified from the first and last name, falling back to the email's local part, then the literal `user`, with a numeric suffix appended on any collision. A generated or user-chosen handle is always 3–30 characters, lowercase letters, digits, and underscores only.

A handle is editable afterward by its owner, subject to: a reserved-word blocklist (common platform words can't be claimed), the same format constraint, and a cooldown between changes. The account's very first manual handle change is never blocked by the cooldown. The cooldown length is a platform-wide, admin-configurable setting, 30 days by default.

## Avatar

An avatar is set by uploading an image; the account's avatar always reflects the most recently uploaded one.

## Self-service profile management

A signed-in user manages their own account through four independent actions — changing one never touches or blocks the others:

- **Name** — first and last name; neither can be cleared to blank once the action is used.
- **Handle** — subject to the handle rules above.
- **Avatar** — uploading a new image replaces the old one immediately.
- **Password** — requires the current password to confirm identity before a new one is set.

## Account status

Every account has a status of `active`, `restricted`, `banned`, or `deleted`, defaulting to `active` on creation.

| Status       | Authentication | Meaning                                       |
| ------------ | -------------- | --------------------------------------------- |
| `active`     | Can sign in    | Full use of the platform                      |
| `restricted` | Can sign in    | Blocked from some of what the platform offers |
| `banned`     | Cannot sign in | Shut out of the platform                      |
| `deleted`    | Cannot sign in | Shut out, with the account's details erased   |

Status is independent of role: a banned admin loses no permission by staying an admin, and an active trader gains none by staying active.
A user's own record can always be updated by that user, and an admin can update any user's record — except status: only an admin can change another account's status, and no account can change its own. Deletion is terminal, so `deleted` is not a status an admin moves an account into by hand.

## Roles & permissions

Every user holds exactly one role, granted through role membership rather than a bare attribute on the user record. Two roles exist:

- **trader** — buy and sell; held by every account by default, since Mercato is a consumer-to-consumer marketplace where every user can act as both buyer and seller.
- **admin** — full platform access; held only by platform staff, and never assigned through any self-service or other public action.

A role's actual capabilities come from the permissions granted to it, not the role name itself — granting or revoking a permission on a role takes effect for every user holding that role, without a schema change.
