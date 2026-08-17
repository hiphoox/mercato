---
type: guide
title: Storage Adapters
description: How to add a new Mercato.Ports.Storage adapter (e.g. Tigris/S3) alongside the local-disk default.
tags: [guide, storage, s3, tigris, adapters]
timestamp: 2026-08-14T00:00:00Z
---

Mercato has one `Mercato.Ports.Storage` adapter today — `Mercato.Ports.Storage.Local` (see [ports.md](../architecture/ports.md)). This is the path for adding another one, for Tigris or any other provider.

## 1. Implement the Behaviour

Add `Mercato.Ports.Storage.<Provider>` at `lib/mercato/ports/storage/<provider>.ex`, `@behaviour Mercato.Ports.Storage`, implementing `put/3`, `get/1`, `delete/1`, `url/2` with the same return contract as `Mercato.Ports.Storage.Local` — callers must not be able to tell adapters apart, per [principles.md → LSP](../architecture/principles.md#lsp--liskov-substitution).

## 2. Wire Config

Override `:storage_adapter` in `config/runtime.exs`, scoped to the environment that uses it (e.g. only `config_env() == :prod`). `config/config.exs`'s default stays `Mercato.Ports.Storage.Local` for every other environment.

## 3. Credentials

For an S3-compatible provider, [fly-provisioning.md](fly-provisioning.md#2-create-the-storage-bucket-optional) already documents the secrets `fly storage create` sets: `AWS_ACCESS_KEY_ID`, `AWS_ENDPOINT_URL_S3`, `AWS_REGION`, `AWS_SECRET_ACCESS_KEY`, `BUCKET_NAME`. Read these in `runtime.exs` and pass them into the adapter's own config (`config :mercato, Mercato.Ports.Storage.Tigris, ...`), not hardcoded in the module.

## 4. HTTP Client

Not yet decided: speak the S3-compatible API directly with `Req` (already a dependency, per [coding-standards.md](../architecture/coding-standards.md)), or add a dedicated client (`ex_aws` + `ex_aws_s3`) if request-signing complexity warrants the extra dependency.

## 5. `url/2`

Local disk serves files through `Plug.Static`; an object-storage adapter returns the provider's own object URL instead — a public bucket returns a direct URL, a private bucket returns a signed one. Decide bucket visibility before implementing this callback, since it changes the return value and whether `opts` (e.g. `expires_in`) is used.

## 6. Testing

Once a second adapter exists, add `Mox` and a `Mox.defmock/2` stub for `Mercato.Ports.Storage` in `test/support`, and have callers swap adapters in tests via `Application.put_env/3` — not needed while `Local` is the only adapter, per [ports.md → Testing](../architecture/ports.md#testing).
