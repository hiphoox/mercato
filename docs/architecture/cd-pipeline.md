---
type: architecture
title: CD Pipeline
description: Continuous deployment workflow, environments, and triggers for shipping to Fly.io.
tags: [cd, github-actions, fly-io, deployment]
timestamp: 2026-08-13T00:00:00Z
---

The CD pipeline delivers verified code to Fly.io, using the `fly deploy` mechanics defined in [infrastructure-and-deployment.md](infrastructure-and-deployment.md).

## Workflow execution

The CD pipeline is implemented using **GitHub Actions** (`.github/workflows/cd.yml`).

**Currently manual-only (`workflow_dispatch`):** the project is still in early development and not yet deployed to Fly.io, so the automatic push/tag triggers are disabled. A run is started by hand from the Actions tab, and which job executes still depends on the ref the run is dispatched against — `refs/heads/main` runs `deploy-staging`, a `refs/tags/v*.*.*` ref runs `deploy-production`.

The intended steady-state triggers (to restore once the project starts deploying regularly) are:

- **Push to `main`:** Deploys to the **staging** [GitHub Environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment). `main` is protected — a pull request, a passing [CI](ci-pipeline.md) status check, and an up-to-date branch are all required before merge — so every push here is already quality-gated.
- **Push of a version tag (`v*.*.*`):** Deploys to the **production** GitHub Environment. Tagging a commit is the deliberate release action described in [git-strategy.md](git-strategy.md). The production environment is restricted to tags matching `v*.*.*`, and a tag ruleset restricts who can push those tags — that combination is the approval gate (required reviewers on environments is unavailable on a personal-account private repo at any plan tier).

## Deploy targets

Each job runs `flyctl deploy --remote-only` scoped to its GitHub Environment, reading identically named variables and secrets from that environment's own store:

| Target | Trigger | Environment | Variable | Secret |
| :--- | :--- | :--- | :--- | :--- |
| Staging | Push to `main` | `staging` | `FLY_APP_NAME` | `FLY_API_TOKEN` |
| Production | Push of tag `v*.*.*` | `production` | `FLY_APP_NAME` | `FLY_API_TOKEN` |

The workflow logic is identical for both jobs — only the `environment:` key differs, so GitHub resolves `vars.FLY_APP_NAME`/`secrets.FLY_API_TOKEN` from the matching environment automatically. Currently both environments point at the same single personal Fly.io instance, so a `main` push and a tag push deploy to the same app. Splitting staging and production onto separate Fly.io apps later requires only updating each environment's variable/secret values, not the workflow file.

## Concurrency

Deploys are grouped by `github.ref` (`cd-${{ github.ref }}`), so multiple pushes to the same branch or tag queue rather than run concurrently against the same environment.

## Schema maintenance

Migrations are not a separate CD step. As described in [infrastructure-and-deployment.md](infrastructure-and-deployment.md), `mix ash.migrate` runs as a Fly.io release command during `flyctl deploy`, applying pending migrations before the new version serves traffic.
