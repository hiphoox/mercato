---
type: feature
title: Admin Users Dashboard
description: The admin-only listing of every account on the platform, with search, status filter, and paging.
tags: [feature, admin, users, listing]
timestamp: 2026-08-21T00:00:00Z
---

The users dashboard is the admin's view of every account on the platform, at `/admin/users`. It surfaces accounts for review, lets an admin move one between account statuses, and lets an admin delete one.

## Access

Reaching the page requires the `admin:access` permission (see [security.md](../../architecture/security.md)). A visitor who is not signed in is sent to sign-in; a signed-in user without the permission is sent home. The listing itself carries the same requirement, so the data is refused rather than filtered to nothing.

The sidebar's Admin section appears only for an account holding the permission. Hiding it is presentation — the routes behind it are gated in their own right.

## What a row shows

One row per account, covering every account regardless of status — including the admin's own:

| Column | Content |
|---|---|
| User | Avatar, display name, and `@handle` |
| Email | The account's email address |
| Status | `Active`, `Restricted`, `Banned`, or `Deleted`, as a badge |
| Role | Every role the account holds, capitalised and alphabetical, or `—` when it holds none |
| Last active | Relative time since the account was last active, or `Never` |
| Actions | A menu of the statuses the account can be moved into, and deletion where it is offered |

The status badge colours track what the status means for the account: green for active, amber for restricted, red for banned, grey for deleted.

**Role is plain text, not a badge.** The status badge beside it is the row's one colour signal; a second badge would compete with it. Every account holds the `trader` role from registration, so the column is populated in practice — the `—` fallback covers a role removed after the fact.

**Display name** falls back in three steps: a deleted account always reads `Deleted user`; an account with neither first nor last name reads `Name not provided`; otherwise the names are joined. Both fallbacks render in a muted italic, so a placeholder never reads as a real name.

**A deleted account is anonymised in the listing** — no avatar image, no name, no handle, and `Erased on deletion` in place of the email — and the whole row is dimmed. The row exists to show that an account was there, not to keep its former owner findable. The listing is the only place on the platform that still shows a deleted account; see [account-deletion.md](../../domain/users/account-deletion.md).

## Account statuses

| Status | What it means |
|---|---|
| Active | Full use of the platform |
| Restricted | Can sign in, but is blocked from some of what the platform offers |
| Banned | Cannot sign in |
| Deleted | Cannot sign in; the account's details are erased |

## Changing an account's status

Each row carries an actions menu, opened from a three-dot button. It offers every status the account is not currently in — reactivating, restricting, or banning — and applies the change in place, without leaving the listing.

Moving an account to `Restricted` or `Banned` asks for confirmation first, naming the account and what the change costs the person. Reactivating applies straight away, since it takes nothing away.

`Deleted` is never offered as a status. Deletion erases the account rather than relabelling it, so it is a separate item rather than another entry in the same list.

Two rows carry no status menu at all: the admin's own, so an admin cannot lock themselves out, and a deleted account, whose row is a record that an account was there rather than one still being managed. The menu is also absent for an admin who can read the listing but holds no permission to update an account.

A status change re-counts the filter chips and re-applies the current search and status filter, so an account that no longer matches the applied filter drops out of the listing.

## Deleting an account

The same actions menu carries a `Delete account` item, set apart from the status items above it — everything above is reversible, this is not. Choosing it confirms first, naming the account and saying that it will be signed out for good and its details erased.

Deletion is offered only for an ordinary account someone else holds. It is withheld from the admin's own row, from another admin's row, from an account already deleted, and from an admin holding no permission to delete. An admin leaving the platform deletes their own account from their profile page.

A deleted account stays in the listing as an anonymised, dimmed row with no menu, and the status chip counts are re-counted so the account moves from its old chip to `Deleted`. What deletion actually erases is covered in [account-deletion.md](../../domain/users/account-deletion.md).

Both kinds of change are visible to the account holder, not just to the admin: moving an account to a new status emails them, and so does deleting it. Nothing an admin does here happens silently.

## Search, filter, and paging

Search matches, case-insensitively, on any part of a first name, last name, handle, or email. An empty search matches everything.

A status chip narrows the listing to one status; the `All` chip clears it. Each chip carries a count of accounts in that status. **Counts describe the platform, not the current search** — they don't shift while a search is typed, so they stay usable as a starting point for narrowing down.

An applied search or status filter is echoed as a removable chip, alongside a control clearing both at once. When a filter matches nothing, the page names the filters that produced the empty result rather than showing a bare "no results".

Accounts are listed 20 to a page, most recently active first, with an account that has never been active last. The current search, status, and page are held in the URL, so a filtered listing is a shareable link and the browser's back button steps back through filters.

## Layout

From the `md` breakpoint up, accounts render as a table with a sticky header and its own scroll area. Below it, each account becomes a card with the same fields as labelled rows. Both are one listing with one set of paging controls.
