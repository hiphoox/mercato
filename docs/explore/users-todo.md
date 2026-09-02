---
type: explore
title: Users Todo
description: Backlog of user-account capabilities, split into MUST and NICE TO HAVE.
tags: [users, todo, backlog, auth, roles]
timestamp: 2026-09-01T00:00:00Z
---

Working backlog for user accounts — signup, login, logout, roles and permissions. Domain rules for what already exists live in [docs/domain/users/](../domain/users/index.md); this file tracks what is left to build.

- **MUST** — required before the feature is complete.
- **NICE TO HAVE** — the extension surface, built when a real use case asks for it.

Item 44 is the exception to that split: it is a MUST, but for [orders-todo.md](orders-todo.md) rather than for this area, which is why it sits in this file unbuilt while everything else in MUST is done.

## MUST

### Users admin dashboard

31. [x] List/search users, view detail (roles held, status, `last_active_at`, linked identities)
32. [x] Change status (ban/reactivate) from the dashboard

### Account status, future extensions

38. [x] `restricted` status (blocks messaging/commenting, still allows buy/sell) — add once a messaging/comments feature exists to gate
39. [x] Soft-delete + anonymization on account deletion (clear PII, keep `id`/history) — split out of the Domain model MUST list; design and build as its own todo

### Fulfillment details

44. [ ] Address held against a user, captured when an action first needs it rather than at signup — a seller's origin before publishing, a buyer's destination at checkout. Phase 1 for orders rather than for users: publish cannot be gated on a shipping origin that does not exist, and checkout cannot ask for a destination it has nowhere to put. This item is only the account's side of it — needs [shipping 5](shipping-todo.md) and [shipping 6](shipping-todo.md) for what an address holds, and [shipping 7](shipping-todo.md) for who may read one

---

## NICE TO HAVE

### Auth strategies (additional providers + pluggability)

24. [ ] Add Google, Apple, Facebook OAuth2 strategies + magic link — coded and deployable, but off until an admin enables them
25. [ ] Model `user_identities` via `AshAuthentication.UserIdentity` extension (one row per linked provider, auto-link by verified email)
26. [ ] Design the generic "custom provider" extension point: a dev implements an `ash_authentication` strategy (or a Mercato-defined behaviour wrapping one) and registers it — once deployed, it automatically appears in the admin dashboard as a toggleable entry, no core code changes needed to surface it
27. [ ] Runtime enabled/disabled state stored in DB (new lightweight resource, e.g. `Mercato.Accounts.AuthStrategySetting` — one row per registered strategy: `strategy_name`, `enabled?`)
28. [ ] Enforce the toggle in two places: (1) hide disabled strategies from sign-in/register UI, (2) reject auth attempts through a disabled strategy server-side
29. [ ] Doc: how to add a new custom provider (interface contract, auto-discovery mechanism)
30. [ ] Tests: strategy enable/disable + custom-strategy plumbing

### Users admin dashboard

33. [ ] Manage roles/permissions from the dashboard (assign/revoke roles, edit `role_permissions` grants) — the RBAC schema is MUST for v1, but a UI on top of it is nice-to-have; `iex`/seed-level management is enough at first
34. [ ] Strategy management panel — list registered strategies, toggle `enabled?` per strategy
35. [ ] Policy tests: non-admin blocked from dashboard/status-change action; admin allowed
36. [ ] Audit log of user actions (who changed what, when) — natural follow-up once the dashboard exists, not built speculatively

### Profile fields, future extensions

37. [ ] `phone` + `phone_verified_at` — paired with an OTP verification flow later, not built now

### Roles system, future extensions (undesigned, revisit when a real deployment needs them)

40. [ ] Session-active-role switching (a user holding multiple roles at once, switchable per session, Gloset-style) — only if a real multi-role use case shows up
41. [ ] "Business/trader-tier" upgrade concept (bulk tools, different commission) — separate role/attribute layered on top of `trader`, not a replacement for it

### Public profile

43. [ ] Seller activity indicator derived from `last_active_at`, shown on the seller's card and profile

### Owned by other areas

42. [ ] Bank/payout account details — see [payments-todo.md](payments-todo.md)
45. [ ] Referrals, and the credit a referral issues — needs platform credit, see [payments-todo.md](payments-todo.md)
46. [ ] Moderation roles (curator, invisible moderator) — see [admin-todo.md](admin-todo.md)
47. [ ] Vacation mode: a seller flag pausing their own availability without pausing each listing by hand, set and cleared by the seller rather than an admin, and distinct from an account status
48. [ ] Notification preferences per category and channel — no area owns notifications yet

## Waiting on

| Area | Why |
| :--- | :--- |
| [shipping-todo.md](shipping-todo.md) | An account can hold an address, but what one holds and who may read it are decided there. Mutual: shipping waits on users in turn |
| [payments-todo.md](payments-todo.md) | Payout account details, and the credit a referral issues |
| [admin-todo.md](admin-todo.md) | Moderation roles are an admin concern layered on the role model |
| [disputes-todo.md](disputes-todo.md) | A seller's dispute rate feeding their account standing, in Phase 2 |
| Notifications | Per-category, per-channel preferences need channels to exist; no area owns notifications yet |

## Depended on by

| Area | Why |
| :--- | :--- |
| [orders-todo.md](orders-todo.md) | Checkout captures a destination address and publish requires an origin; both need an account able to hold one |
| [shipping-todo.md](shipping-todo.md) | An address hangs off an account. Mutual |
| [social-todo.md](social-todo.md) | A restricted account cannot comment, which needs account status to gate on |
