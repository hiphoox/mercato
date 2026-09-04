---
name: writing-docs
description: Use when creating, editing, converting, or splitting any markdown file under docs/ (architecture, domain, explore, guides) in this project — the baseline knowledge docs that follow Open Knowledge Format (OKF) with YAML frontmatter, one-concern-per-file, and an agent-discoverable index.
---

# Writing OKF Baseline Docs

## Overview

`docs/` holds this project's baseline knowledge (architecture, domain, explore). These are reference files agents pull on demand — none load by default. Every file is a node in a machine-readable knowledge graph: markdown body + OKF YAML frontmatter. The whole design exists so an agent opens **exactly the one doc it needs** and spends no tokens on anything else.

Four rules make that work: OKF frontmatter, one concern per file, a current index, and updating docs alongside the code they describe. Follow all four on every new or edited doc — automatically, without being asked.

**Two rules matter most, everything else in this skill exists to serve them:** One File = One Concern (how docs are structured) and Behavior, Not Implementation (what goes in them, see Style below). A doc that mixes concerns costs every future agent tokens; a doc full of module/function names instead of rules is wrong even when it's fresh and accurate.

## When to Use

- Writing a new `docs/` file within an existing section.
- Editing an existing `docs/` file.
- Converting a legacy doc that has no frontmatter.
- A doc has grown to cover more than one concern and needs splitting.

## Format (required, opens every file)

```yaml
---
type: architecture        # section-generic: architecture | domain | feature | explore | guide | index
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

## Where Docs Live

`docs/` has four fixed sections:

- `architecture/` — system shape and cross-cutting standards.
- `domain/` — entities, business rules, ER diagrams.
- `explore/` — research/decisions for capabilities not yet built, plus the per-area `<area>-todo.md` backlogs tracking what is left to build. A research file graduates to the owning section once built, updating `type` and content to match the real implementation.
- `guides/` — step-by-step how-tos for occasional tasks (provisioning an environment, adding an adapter). A guide may describe a step that doesn't exist yet, since the procedure is the content — it doesn't need to graduate once the step exists.

This is a closed set — never create a new top-level `docs/<section>/` folder on your own judgment; ask the user first if a doc genuinely doesn't fit any of the four.

## One File = One Concern

An agent must be able to pull *just* security, or *just* streams, without loading a monolith. When a doc spans more than one concern, split it into separate OKF files rather than keeping it combined. Flag this when converting or reviewing existing docs, not only when writing new ones.

**Length is a signal to recheck the concern boundary.** Past ~100-150 lines, a doc is usually covering more than one concern — split it. Don't pad a doc to dodge the threshold, and don't split apart facts a reader needs together.

## Keep Docs Discoverable

Each `docs/<section>/` has an `index.md` (`type: index`) mapping its files. When you add, rename, or split a doc, update that section's index in the same change. Each entry is a link + one line naming the concern **and when to open it**:

```markdown
- [security.md](security.md) — Authentication and authorization model. Read it when working on auth, sessions, tokens, or permissions.
```

## Update Docs Alongside Code

When code changes, update the doc describing it in the same change — not "eventually." A stale doc (describing removed fields, wrong defaults, capabilities that no longer exist) is read as authoritative and is worse than no doc at all.

This is a doc about the current system, not a roadmap: never write "planned" / "nice to have" / "future extension" scope notes into it — track it in the area's `docs/explore/<area>-todo.md` backlog instead. `docs/explore/` is the one exception to this rule, since it exists specifically to hold not-yet-built research, decisions, and scope.

**ER diagrams and other docs describing an Ash resource are a special case:** once the resource exists in code, the code is authoritative for its specifics (attributes, types, defaults) — reconcile the diagram/doc to match the code, not the other way around.

## Style

### Behavior, Not Implementation

A doc describes **what the system does** — its rules, guarantees, and observable behavior — not **how the code achieves it**. A reader should be able to act on the doc without knowing the language, framework, or module structure underneath.

- Write: "a user's email is visible only to themselves." Not: "`Mercato.Accounts.User.Checks.ActorHasRole` — an `Ash.Policy.SimpleCheck` — loads `user_roles` and matches on role name."
- Write: "a banned or deleted account cannot sign in." Not: "`prepare build(filter: [status: :active])` on `sign_in_with_password`."
- Module names, function names, action names, check/validation module names, config snippets, and framework-specific mechanism names (a specific check type, a specific DSL macro) are all implementation detail — they belong in the code, which is always the authoritative, current source for exactly that.

This isn't the same rule as "code is authoritative for a resource's specifics" (see Update Docs Alongside Code above) — that rule is about *trusting* the code over a stale doc. This rule is about what the doc should *contain* in the first place: even a perfectly fresh, perfectly accurate doc is wrong if it's full of module/function names instead of the rules those modules implement. If you catch yourself naming a module, a check, or a function to explain a behavior, stop and write the behavior itself instead — the name is not the point.

### State What IS

Write plain declarative facts about the current system. Cut justification prose about roads not taken — `"X, not Y"`, `"rather than"`, `"instead of"`, `"not a formal Z because…"`. A reader needs the current shape, not a design-rationale record. Keep a contrast only when it is load-bearing (e.g. a table cell documenting two exclusive states).

## Reference

| Check | Rule | Common mistake |
|-------|------|-----------------|
| Frontmatter | All five fields; `type` lowercase & section-generic, never a unique per-file value | Keeping the `# H1` alongside `title`; a multi-sentence `description` |
| Concern | Exactly one; split past ~100-150 lines | Combining concerns "to save a file" |
| Index | Entry added/edited with "Read it when…" in the same change | Forgetting the index — an unlisted doc is undiscoverable |
| Freshness | Update the doc in the same change as the code | Letting a doc go stale "for later" |
| Resource docs | Code is authoritative for a resource's specifics once it exists | Trusting a stale ER diagram over the actual resource code |
| Behavior vs. implementation | Describe rules/behavior; leave module/function/check names to the code | Naming a module or function to explain a behavior instead of stating the behavior |
| Roadmap notes | None outside `docs/explore/` — no "planned" / "nice to have" / "future" | Writing roadmap notes into a doc about existing code |
| Style | Declarative facts, no negation prose | Explaining what wasn't chosen ("X, not Y") |
