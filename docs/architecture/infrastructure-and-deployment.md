---
type: architecture
title: Infrastructure & Deployment
description: Compute, persistence, and deployment mechanics on Fly.io.
tags: [infrastructure, fly-io, deployment, sqlite, infra-less]
timestamp: 2026-07-23T00:00:00Z
---

The technical infrastructure and deployment machinery for Mercato, leveraging Fly.io's micro-VM architecture. Mercato is built to be **infra-less as much as possible**: no separate database server, no required external services beyond the app itself — everything the app needs to run defaults to living on the same Fly.io instance, with external providers (object storage, payments, shipping) as opt-in, swappable adapters rather than hard dependencies.

## High-level traffic flow

```text
User -> Fly Proxy (SSL/TLS termination) -> Phoenix App -> SQLite (local file on Fly volume) / Tigris (S3, optional)
```

## Infrastructure specifications

### Compute & edge

- **Hosting platform:** **Fly.io** (single instance).
- **Process management:** Managed by Fly.io micro-VMs. The application is packaged as a Docker image and deployed via the `fly` CLI.
- **Edge routing:** **Fly Proxy** handles all HTTPS termination, SSL/TLS certificate management, and routing to the application.
- **Secrets management:** Handled via `fly secrets`. These are injected as environment variables at runtime and loaded into the application via `config/runtime.exs`.

### Persistent data store

Mercato runs on a single shared **SQLite** database — a file on a Fly.io persistent volume, not a separately provisioned or managed database service. This is the core of the infra-less approach: no database cluster to create, attach, or operate. See [data-architecture.md](data-architecture.md) for the data model, migrations, and retention policy.

### Object storage

Large assets — product images and other uploaded files — go through a pluggable storage adapter, with the database storing only references (URLs/keys), per [data-architecture.md](data-architecture.md). The **default adapter is local disk**, requiring no external service at all. **Tigris** (S3-compatible) is an opt-in adapter for deployments that want object storage decoupled from the app's own volume.

## Deployment machinery

The technical delivery of the application is automated to ensure environment parity and atomic updates. For the human process of releasing a version (PRs, version bumps, tagging), refer to [git-strategy.md](git-strategy.md). For the GitHub Actions workflow that triggers deploys and the staging/production environments it targets, see [cd-pipeline.md](cd-pipeline.md).

### Delivery pipeline

| Component | Tool/Decision | Rationale |
| :--- | :--- | :--- |
| **Source Control** | **GitHub** | Standard for collaboration and CI integration. |
| **CI Engine** | **GitHub Actions** | Automates quality gates (compilation, linting, testing) as defined in [ci-pipeline.md](ci-pipeline.md). |
| **Build Artifact** | **Docker Image** | Standard Fly.io deployment unit, ensuring environment parity. |
| **Delivery Method** | **`fly deploy`** | Fast, atomic deployments with integrated health checks. |

### Server initialization

New environments must be provisioned with a Fly.io app, a persistent volume for the SQLite database, and the required secrets — plus a Tigris bucket only if that storage adapter is in use — see [fly-provisioning.md](../guides/fly-provisioning.md) for the exact runbook.

## Schema maintenance

Migrations are generated from Ash resource definitions (`mix ash.codegen`) and applied with `mix ash.migrate` — see [data-architecture.md](data-architecture.md) for the full migration workflow. As part of deployment, `mix ash.migrate` runs as a Fly.io release command, applying pending migrations before the new version starts serving traffic.
