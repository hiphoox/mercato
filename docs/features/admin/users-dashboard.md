---
type: feature
title: Admin Users Dashboard
description: The admin-only listing of every account on the platform, with search, status filter, and paging.
tags: [feature, admin, users, listing]
timestamp: 2026-08-20T00:00:00Z
---

The users dashboard is the admin's view of every account on the platform, at `/admin/users`. It is read-only: it surfaces accounts for review and does not change them.

## Access

Reaching the page requires the `admin:access` permission (see [security.md](../../architecture/security.md)). A visitor who is not signed in is sent to sign-in; a signed-in user without the permission is sent home. The listing itself carries the same requirement, so the data is refused rather than filtered to nothing.

The sidebar's Admin section appears only for an account holding the permission. Hiding it is presentation — the routes behind it are gated in their own right.

## What a row shows

One row per account, covering every account regardless of status — including the admin's own:

| Column | Content |
|---|---|
| User | Avatar, display name, and `@handle` |
| Email | The account's email address |
| Status | `Active`, `Banned`, or `Deleted`, as a badge |
| Role | Every role the account holds, capitalised and alphabetical, or `—` when it holds none |
| Last active | Relative time since the account was last active, or `Never` |

**Role is plain text, not a badge.** The status badge beside it is the row's one colour signal; a second badge would compete with it. Every account holds the `trader` role from registration, so the column is populated in practice — the `—` fallback covers a role removed after the fact.

**Display name** falls back in three steps: a deleted account always reads `Deleted user`; an account with neither first nor last name reads `Name not provided`; otherwise the names are joined. Both fallbacks render in a muted italic, so a placeholder never reads as a real name.

**A deleted account is anonymised in the listing** — no avatar image, no name, and `Erased on deletion` in place of the email — and the whole row is dimmed. The row exists to show that an account was there, not to keep its former owner findable.

## Search, filter, and paging

Search matches, case-insensitively, on any part of a first name, last name, handle, or email. An empty search matches everything.

A status chip narrows the listing to one status; the `All` chip clears it. Each chip carries a count of accounts in that status. **Counts describe the platform, not the current search** — they don't shift while a search is typed, so they stay usable as a starting point for narrowing down.

An applied search or status filter is echoed as a removable chip, alongside a control clearing both at once. When a filter matches nothing, the page names the filters that produced the empty result rather than showing a bare "no results".

Accounts are listed 20 to a page, most recently active first, with an account that has never been active last. The current search, status, and page are held in the URL, so a filtered listing is a shareable link and the browser's back button steps back through filters.

## Layout

From the `md` breakpoint up, accounts render as a table with a sticky header and its own scroll area. Below it, each account becomes a card with the same fields as labelled rows. Both are one listing with one set of paging controls.
