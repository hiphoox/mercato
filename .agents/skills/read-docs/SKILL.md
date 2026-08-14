---
name: read-docs
description: Use when starting any work on this project — implementing, changing, debugging, or reviewing code, schema, or docs — to find and read the specific docs/ files that govern the task, and only those, before acting. Triggers whenever you are about to write code or make a decision that a baseline doc (architecture, domain, feature) may already constrain.
---

# Read the Docs That Govern the Task

## Overview

`docs/` holds this project's baseline knowledge, built so an agent pulls **exactly the file it needs** on demand. Before touching code or making a design call, consult the docs that govern that concern — and only those. Two failures to avoid, both costly:

- **Skipping** — coding on assumption, then contradicting an established standard, entity rule, or feature spec.
- **Over-reading** — loading whole folders "to be safe" and burning the token budget the split was designed to save.

The index files exist to resolve both: they name each doc's concern and when to open it, so you open the right one and stop. Correct information comes first — start narrow, and widen the search when the index does not point you to the answer. Never guess to stay minimal.

## The Discovery Procedure (index-first)

1. **Name the concern(s)** of your task — e.g. "writing a LiveView", "changing the transactions schema", "the checkout flow".
2. **Open `docs/index.md`** to find which section owns the concern, then that section's own `index.md`. **If the task involves something that doesn't exist in the codebase yet** (a new library, integration, or capability), check `docs/explore/index.md` first — the research or decision may already be done.
3. **Open only the files whose "Read it when…" line matches.** The one-liner tells you before you open it — do not read every file in a section.
4. **If a resource exists in code for what you're reading about** (an Ash resource, a config module), the code is authoritative — a doc may lag behind it. Trust the code over the doc when they disagree, and note the gap.

## Rules

- **Read before acting.** Consult the governing doc before writing the code or committing to a design.
- **Start narrow, widen as needed.** Open the file the index points to first. If it does not answer your question, read adjacent docs or grep `docs/` — reading more is fine; guessing is not.
- **Prefer links, then explore.** Let the index and cross-references route you first; when they do not cover your concern, search the tree freely.
- **Re-open, don't remember.** Docs evolve — read the current file rather than relying on recall from a past session.

## When the Index Doesn't Resolve It

The index one-liners cover the common concerns, not every question. When none matches, or the file you opened doesn't answer you:

1. **Grep `docs/`** for the entity, module, term, or error you're working with.
2. **Read adjacent docs** — the sibling files in the same section, or a cross-reference from the file you're in.
3. **Check `AGENTS.md`** for a pointer you missed.
4. Still unclear? Proceed with best judgment and **note the gap** so the doc can be filled — a missing doc is a finding, not a blocker.

## Red Flags — STOP

- "I'll just start coding and check docs if something breaks."
- "Let me read the whole `docs/` folder first."
- "I already know this project's conventions."
- "This change is too small to need the docs."

Each means: open the section index, read the one or two files it points you to, then proceed.
