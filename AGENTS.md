# Mercato — Project Guide

Mercato is a general-purpose C2C marketplace platform, designed as a foundation for
building any marketplace on top of it.
Phoenix 1.8 + Ash Framework, LiveView + Tailwind 4, SQLite via AshSqlite. Mix/Hex.

**Rule of thumb — infra-less as much as possible.** Nothing may require a separate
database server or an external service beyond the app itself. SQLite is the foundation
that keeps it that way: the data layer is swappable, but no swap may introduce a required
external database service. External providers (object storage, payments, shipping) are
opt-in, swappable adapters, never hard dependencies. When adding an integration or a
persistence need, the local/in-app option is the default and the external provider is the
pluggable option — not the other way around.

## Quality gates

- `mix quality` — run for checking quality.
- `mix precommit` — run before committing.

Both must be clean — not "clean except what I didn't introduce". Every other command is in
[docs/architecture/cli-commands.md](docs/architecture/cli-commands.md); check it before
doing by hand what a command already does.

## Documentation

Start at [docs/index.md](docs/index.md) and open only what it points you to — one source of
truth per concern, read on demand, nothing loaded upfront.

## Skills

When work on this project, ALWAYS USE THE SKILLS.

| Skill                      | Purpose                                                                                      |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| **`implementing-changes`** | The entry point for changing code, schema, or docs — it invokes the others as its own steps. |
| `reading-docs`             | Understand the project domain and guidelines before making changes or answering questions.   |
| `understanding-code`       | Understand the codebase and its dependencies before making changes or answering questions.   |
| `writing-docs`             | Document, and keep documentation up to date, when making changes.                            |
| `answering-questions`      | Answer a conceptual question instead of making a change.                                     |

`reading-docs` and `understanding-code` come before any work — changes or answers alike. Never
explore with Grep/Read before `understanding-code`, even for a single lookup.
