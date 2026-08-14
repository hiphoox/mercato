---
name: write-docs
description: Use when creating, editing, converting, or splitting any markdown file under docs/ (architecture, domain, features, explore) in this project — the baseline knowledge docs that follow Open Knowledge Format (OKF) with YAML frontmatter, one-concern-per-file, and an agent-discoverable index.
---

# Writing OKF Baseline Docs

## Overview

`docs/` holds this project's baseline knowledge (architecture, domain, features). These are reference files agents pull on demand — none load by default. Every file is a node in a machine-readable knowledge graph: markdown body + OKF YAML frontmatter. The whole design exists so an agent opens **exactly the one doc it needs** and spends no tokens on anything else.

Three rules make that work: OKF frontmatter, one concern per file, and a current index. Follow all three on every new or edited doc — automatically, without being asked.

**The most important rule is One File = One Concern.** Everything else in this skill exists to serve it — a doc that mixes concerns costs every future agent tokens, no matter how clean its frontmatter is.

## When to Use

- Writing a new `docs/` file within an existing section.
- Editing an existing `docs/` file.
- Converting a legacy doc that has no frontmatter.
- A doc has grown to cover more than one concern and needs splitting.

## The Frontmatter (required, opens every file)

```yaml
---
type: architecture        # section-generic: architecture | domain | feature | index
title: Short Title        # the subject only — "Principles", "Security". No project name suffix.
description: One short sentence.
tags: [relevant, lowercase, tags]
timestamp: 2026-07-23T00:00:00Z   # date added/updated, midnight UTC
---
```

- `type` is the **only strictly required** OKF field, but write all five above. It is lowercase and generic per section — `architecture` for every architecture doc, `index` for a directory map — never a unique per-file value.
- `title` is short. Delete the original `# H1` heading — the frontmatter `title` replaces it. Never keep both.
- `description` is one short sentence.
- `tags` are lowercase.
- Add `resource:` only when the doc genuinely points at one external resource. Omit otherwise.

## One File = One Concern

An agent must be able to pull *just* security, or *just* streams, without loading a monolith. When a doc spans more than one concern, split it into separate OKF files rather than keeping it combined. Flag this when converting or reviewing existing docs, not only when writing new ones.

**Length is a signal to recheck the concern boundary.** Past ~100-150 lines, a doc is usually covering more than one concern — split it. Don't pad a doc to dodge the threshold, and don't split apart facts a reader needs together.

## Keep the Index Discoverable

Each `docs/<section>/` has an `index.md` (`type: index`) mapping its files. When you add, rename, or split a doc, update that section's index in the same change. Each entry is a link + one line naming the concern **and when to open it**:

```markdown
- [security.md](security.md) — Authentication and authorization model. Read it when working on auth, sessions, tokens, or permissions.
```

`docs/` has four fixed sections — `architecture/`, `domain/`, `features/`, `explore/` — listed in `docs/index.md`. This is a closed set: never create a new top-level `docs/<section>/` folder on your own judgment. If a doc genuinely doesn't fit any of the four, ask the user before adding a section.

## `docs/explore/` — Research for What Doesn't Exist Yet

Holds decisions/research for not-yet-built capabilities — exempt from "Code Is the Source of Truth" below. Once built, the file graduates: move it to the owning section (usually `architecture/`), update `type` and content to match the real implementation, and update both indexes.

## Code Is the Source of Truth Once It Exists

A doc (an ER diagram, a config reference, a flow description) can describe a design before code exists for it — while it does, the doc is authoritative. Once real code exists for what a doc describes (an Ash resource, a module, a config file), the code — not the doc — is authoritative for the specifics. Before trusting or editing a doc that has a code counterpart, open the code and reconcile the doc to match it, not the other way around.

## Style: State What IS

Write plain declarative facts about the current system. Cut justification prose about roads not taken — `"X, not Y"`, `"rather than"`, `"instead of"`, `"not a formal Z because…"`. A reader needs the current shape, not a design-rationale record. Keep a contrast only when it is load-bearing (e.g. a table cell documenting two exclusive states).

## Quick Reference

| Check | Rule |
|-------|------|
| Frontmatter present | All five fields, `type` lowercase & section-generic |
| H1 heading | Removed — `title` replaces it |
| Concern count | Exactly one; split if more |
| Length | Past ~100-150 lines, recheck concern boundary |
| Index updated | Entry added/edited with "Read it when…" |
| Style | Declarative facts, no negation prose |

## Common Mistakes

- **Keeping the `# H1`** alongside the frontmatter `title` — remove the H1.
- **Unique `type` per file** — `type` is section-generic, not the doc's title.
- **Long `description`** — one sentence.
- **Forgetting the index** — a doc absent from `index.md` is undiscoverable.
- **Combining concerns** "to save a file" — defeats the token-saving purpose; split.
- **Letting a doc grow past ~100-150 lines unchecked** — it's almost always mixing concerns by that point; split it.
- **Explaining what was *not* chosen** — state what is.
