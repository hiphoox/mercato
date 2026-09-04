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

| Situation                                           | Skill                                                                              |
| --------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Changing code, schema, or docs                      | **`working-on-changes`** — the entry point; it invokes the others as its own steps |
| Any other work on the repo                          | **`read-docs`** first                                                              |
| Finding, tracing, or confirming code exists         | `understand-code`                                                                  |
| Writing or editing under `docs/`                    | `write-docs`                                                                       |
| A task a CLI/Mix command could do deterministically | `deterministic-commands`                                                           |
| A conceptual question rather than a change          | `answering-questions`                                                              |
