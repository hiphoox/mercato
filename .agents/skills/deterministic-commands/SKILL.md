---
name: deterministic-commands
description: Use before performing any task that a CLI/Mix command could do deterministically instead — creating/resetting the database, running migrations, seeding, generating a resource, etc. Checks docs/architecture/cli-commands.md for a matching command before doing the task by hand, and keeps that list up to date.
---

# Prefer Deterministic Commands Over Manual Work

## Overview

Some tasks in this project have a command that performs them correctly and deterministically — creating the database, running migrations, scaffolding an Ash resource, seeding data. Doing these by hand (writing SQL, hand-crafting a resource file, editing the db directly) is slower and error-prone compared to the command. `docs/architecture/cli-commands.md` is the running list of these commands.

## Procedure

1. **Before doing a task manually**, check `docs/architecture/cli-commands.md` for a command that already does it.
2. **If a matching command exists**, run it instead of doing the task by hand.
3. **If you use or discover a deterministic command not yet in the list** (in this project or, once relevant, in another project's own list), add it to `docs/architecture/cli-commands.md` in the same change — one line, command + what it does — following the `write-docs` OKF conventions. The list only stays useful if it's kept current.
4. **If no command exists**, proceed manually as normal.

## Scope

The list in `docs/architecture/cli-commands.md` is Mercato-specific. If a deterministic command applies broadly across projects (not just this one), note that to the user rather than assuming — it may belong in a global reference instead of this project's docs.
