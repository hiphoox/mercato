---
type: architecture
title: Fly.io Provisioning
description: Runbook for creating the Fly.io app, volume, storage, and secrets an environment needs.
tags: [fly-io, provisioning, runbook, sqlite, tigris]
timestamp: 2026-07-29T00:00:00Z
---

Provisioning a Mercato environment on Fly.io is a manual, one-time setup per environment. This runbook lists the steps in the order they must run — several resources are not created automatically by one another and require a separate command.

## Prerequisites

```bash
brew install flyctl
fly auth login
```

## 1. Create the app

```bash
fly launch --no-deploy
```

Detects the Phoenix app, generates `fly.toml` and a `Dockerfile`, and creates the app on Fly. `--no-deploy` skips deploying immediately so the generated files can be reviewed first.

`fly launch` may offer to create a **Managed Postgres** cluster during this step — decline it. Mercato uses SQLite, so no separate database service is needed; the database is a file on the app's own persistent volume (step 3).

## 2. Create the storage bucket (optional)

Object storage is a pluggable adapter — the default is local disk, which needs no Fly resources at all. Only run this step if the deployment uses the Tigris adapter:

```bash
fly storage create
```

Passing `-n <bucket-name> --app <app-name>` creates the bucket and attaches it to the app in one command, auto-setting the `AWS_ACCESS_KEY_ID`, `AWS_ENDPOINT_URL_S3`, `AWS_REGION`, `AWS_SECRET_ACCESS_KEY`, and `BUCKET_NAME` secrets — skipping the need to set those manually in step 4.

## 3. Create the persistent volume

SQLite needs a durable disk that survives redeploys — a Fly Volume, mounted at the path `DATABASE_PATH` points to:

```bash
fly volumes create <app-name>_data --app <app-name> --region lax --size 1
```

Mount it in `fly.toml` (`[mounts]` section, `source = "<app-name>_data"`, `destination = "/data"` or similar), and set `DATABASE_PATH` to a file under that mount point in step 5.

## 4. Set application secrets

```bash
fly secrets set --app <app-name> KEY=value
```

Required secrets: `SECRET_KEY_BASE`, `DATABASE_PATH`.

Additionally, `AWS_ACCESS_KEY_ID`, `AWS_ENDPOINT_URL_S3`, `AWS_REGION`, `AWS_SECRET_ACCESS_KEY`, `BUCKET_NAME` are needed **only if** the Tigris storage adapter is in use — the default local-disk adapter needs none of them (already set if the bucket was created with `--app`, per step 2). These live only on Fly, scoped to the app — see [infrastructure-and-deployment.md](infrastructure-and-deployment.md) for how they're loaded at runtime. Secrets show as "Staged" until the next deploy applies them.

`SECRET_KEY_BASE` has no external source — generate it locally and set it in one pass, capturing the value before it scrolls off:

```bash
SECRET_KEY_BASE=$(mix phx.gen.secret)
echo "$SECRET_KEY_BASE"
fly secrets set --app <app-name> SECRET_KEY_BASE="$SECRET_KEY_BASE"
```

Fly secrets are write-only — there is no command to read a value back once set. Each value set in this step must also be recorded in a team secrets vault (e.g. 1Password, Bitwarden, Doppler) so it can be referenced or rotated later without being locked out of the original value. Secret values are never committed to `docs/` or any other git-tracked file. IMPORTANT

## 5. Configure CD deploy credentials

The [cd-pipeline.md](cd-pipeline.md) workflow needs its own credentials, set per **GitHub Environment** (`staging`, `production`) — not Fly secrets:

- Variable: `FLY_APP_NAME`
- Secret: `FLY_API_TOKEN` (from `fly tokens create deploy`)

Set both in each environment (Settings → Environments → `staging` / `production`). Restrict `production` to tags matching `v*.*.*` under "Deployment branches and tags", and pair it with the tag ruleset (see [git-strategy.md](git-strategy.md)) restricting who can push those tags — required reviewers on environments is unavailable on a personal-account private repo at any plan tier.
