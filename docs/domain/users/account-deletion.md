---
type: domain
title: Account Deletion
description: What deleting a Mercato account erases, what it keeps, and who may trigger it.
tags: [domain, users, deletion, anonymization, privacy]
timestamp: 2026-08-21T00:00:00Z
---

Deleting an account is terminal and irreversible. The account row survives deletion, carrying the time it was deleted and nothing that identifies who it belonged to. Nothing is ever hard-deleted from the account record itself.

## What deletion erases

Every personal detail the account held is cleared: first name, last name, handle, avatar image, password, and email confirmation. The avatar's stored image file is removed from object storage, not merely unlinked.

The email address is replaced with an opaque placeholder at a domain that can never receive mail. It is not retained in any form, which means **the original address becomes free to register again** — someone who deletes their account and later signs up with the same email gets a genuinely new account, not their old one back.

The account's role membership is removed outright, so a deleted account carries no permissions. Every token issued to the account is revoked, so any session still open elsewhere stops working immediately rather than lasting until it would have expired.

## What deletion keeps

The account row itself, its identifier, and the time of deletion. Transactional history, reviews, and sold items stay on record for accounting, tax compliance, and dispute resolution — attached to an account that no longer names anyone.

## What a deleted account can do

Nothing. It cannot sign in by password or by magic link, its status reads `deleted`, and a session held from before deletion no longer resolves to a user.

## Where a deleted account is still visible

A deleted account is hidden from every part of the platform except the admin users dashboard, which keeps its row so an admin can see that an account was there. That row shows no avatar, no name, and no email.

## Who may delete an account

| Who | Where | What they may delete |
| --- | --- | --- |
| Any signed-in user | Their own profile page | Their own account, only |
| An admin holding the delete permission | The admin users dashboard | Any ordinary account other than their own |

An admin cannot delete their own account from the dashboard, and cannot delete another admin's. An admin leaving the platform deletes their own account from their profile page, the same way anyone else does.

## Notifying the account holder

The account is emailed that it was deleted, in both flows — the person who deleted their own account gets a receipt, and someone whose account an admin deleted finds out that it happened.

The notice goes to the **original address**, sent before anonymisation replaces it, since the placeholder that takes its place can never receive mail. It says what was erased, that past orders stay on record without their details attached, and that the same email may be used to sign up again.

Delivery is best-effort: an account is still deleted if the mail cannot be sent.

## Confirmation

Both flows confirm before anything happens, and both name the account and say what deletion costs.

Self-service deletion asks the user to type their own handle before the confirm button becomes usable. Typing it is the confirmation — no password is asked for, since an account that has only ever signed in by magic link has none.

Admin deletion confirms in one step, the same way restricting or banning an account does.
