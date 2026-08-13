# Mercato

<img src="priv/static/images/mercato-logo.png" alt="Mercato logo" width="128">

Mercato is a general-purpose C2C marketplace platform, built to be infrastructure-less as much as possible. Users buy and sell items through an escrow-style flow where payment is held until delivery is confirmed.

Payment, shipping, and similar third-party vendors are pluggable. Defaults: Google & Apple OAuth, Stripe + Stripe Connect, and Shippo (chosen for its sandbox/test mode).

## Tech stack

Elixir, Phoenix, Ash Framework, LiveView, SQLite, Fly.io. See [docs/architecture/architecture.md](docs/architecture/architecture.md) for the system's shape.

## Prerequisites

- Erlang 29.0.3 and Elixir 1.20.2-otp-29 — install via [asdf](https://asdf-vm.com) using the pinned `.tool-versions` (`asdf install`)

SQLite needs no separate service — the database is a local file, so there's no server to install or run. The Elixir driver downloads a precompiled native binary on common platforms; if none matches yours, it compiles from source and needs a C compiler toolchain (e.g. Xcode Command Line Tools, `build-essential`).

## Getting started

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Documentation

[docs/index.md](docs/index.md) is the source of truth for architecture, domain, and feature docs — start there.

## Contributing

Trunk-based development: `main` is the only long-lived branch, PRs are squashed and merged, and CI must pass before merging. See [docs/architecture/git-strategy.md](docs/architecture/git-strategy.md).
