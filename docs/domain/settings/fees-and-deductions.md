---
type: domain
title: Fees and Deductions
description: The named rows an operator configures for what the platform takes off a seller's earnings and adds to what a buyer pays.
tags: [domain, settings, payments, commission, tax, fees, admin]
timestamp: 2026-09-03T00:00:00Z
---

What a marketplace charges is two tables of named rows an operator manages from the admin area: what is deducted from a seller's earnings, and what is added to what a buyer pays. A commission, a jurisdiction's tax stacked on that commission, and a buyer's protection fee are each one row.

A fresh install has no rows in either table. A seller keeps the whole sale price and a buyer pays it and no more, so a marketplace that charges nothing runs without configuring anything.

## What a row is

Every row has a name and a value. The name is what the row is called on a statement or at checkout, shown exactly as it was typed and never translated. The value is one of two things:

| Value | What it takes |
| :--- | :--- |
| A flat amount | The same amount off every sale, whatever the sale came to |
| A percentage | A share of something else, so what it takes moves with the sale |

A row is one or the other. A flat row has no rate and a percentage row has no amount.

Two rows in the same table may not share a name, since a name is how each is told apart on the statement it appears on.

## What a percentage is a percentage of

A seller deduction that is a percentage names what it is a percentage of: the sale price, or another deduction's amount. A tax charged on a commission is a row that is a percentage of the commission row, which is what makes stacking a jurisdiction's rules a matter of configuration.

A chain of rows may not close on itself, and a row another row is a percentage of stays until nothing depends on it.

A buyer fee that is a percentage is always a percentage of the sale price. A buyer is told what they are paying on top of the price rather than a stack of charges on charges.

## What each side does with them

Seller deductions come off what a seller is paid. Buyer fees are added to the sale price at checkout, so the buyer pays more rather than the seller receiving less.

A buyer reads the fees they are charged as lines of their own beside what the items come to, so what they are paying is broken into its parts rather than shown as one number — see [checking out a group](../carts/carts.md).

Both tables are read on a sale of a given price as a set of lines — one per row, in the order the rows were added — and the total they come to. Nothing is capped: rows adding up to more than the sale read as a total larger than the price rather than a number quietly trimmed to fit.

A listing takes its own copy of the seller table as it is created, and what that listing owes is read against the copy rather than against the table. Changing the table governs what is listed from then on — see [what a sale leaves the seller](../listings/listings.md).

Amounts are held in the currency's minor units and rates in hundredths of a percent, both as whole numbers, so what is taken is arithmetic that never rounds twice. A share of an amount rounds a half unit up.

## Who may change them

Reading both tables is open to everyone, including a visitor with no account: what a purchase comes to is shown before anybody signs in, and a seller weighs what a sale would leave them before they make one.

Changing either is restricted to an operator granted the settings permission — the same permission that governs [the marketplace's own values](marketplace-settings.md).
