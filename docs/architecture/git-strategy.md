---
type: architecture
title: Git Strategy
description: Branching model, release workflow, and versioning.
tags: [git, branching, release, versioning]
timestamp: 2026-07-23T00:00:00Z
---

This document defines the authoritative branching model, merging policies, and release workflow. We employ a **Trunk-Based Development** model to ensure high velocity, minimal integration pain, and a stable production environment.

## Core strategy: Trunk-Based Development

In this model, `main` is the only long-lived branch and the single source of truth for production. All developers integrate their changes frequently into `main` to avoid the "merge hell" associated with long-lived feature branches.

### Branch hierarchy

- **`main`**: The production-ready trunk. Every commit on `main` must be deployable.
- **`feat/` or `feature/`**: Short-lived branches for new functionality. Branched from `main`, merged back into `main`.
- **`fix/`**: Short-lived branches for bug fixes and high-priority hotfixes. Branched from `main`, merged back into `main`.

## Operational policies

### 1. Merge style: Squash and Merge

All feature and fix branches are **squashed and merged**, collapsing incremental development commits into a single, logical commit per feature/fix. This keeps `main`'s history clean, linear, and readable, simplifying auditing and making it clear exactly when a feature was introduced.

### 2. Quality gate: mandatory CI pass

No branch may be merged into `main` without a successful CI run. All checks in [ci-pipeline.md](ci-pipeline.md) (Compilation, Formatting, Static Analysis, and Test Suite) must be green — merge requests are blocked until the quality gates are satisfied.

Branch protection rules and tag protection rulesets are configured on the repository, but GitHub only *enforces* these on a private repository when the owning organization is on GitHub Team or Enterprise. Until the organization is on a qualifying plan, this policy relies on convention (always merge through a reviewed PR, never push directly).

### 3. Versioning: Semantic Versioning (SemVer)

The project follows `MAJOR.MINOR.PATCH` versioning, declared in `mix.exs`.

## Release workflow

The release workflow defines the human steps required to move a verified version of the software into production. For the technical machinery of the deployment (Docker, Fly.io, Volumes), refer to [infrastructure-and-deployment.md](infrastructure-and-deployment.md).

### Production deployment

We use a "Version-Bump PR" approach to ensure releases are explicit and tracked.

1. **Version bump**: Create a short-lived branch `version-bump/vX.Y.Z`, update the version in `mix.exs`, and merge it into `main`.
2. **Tag**: Tag the merged commit on `main`:
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```
3. **Deploy**: Pushing the tag automatically triggers a production deployment — see [cd-pipeline.md](cd-pipeline.md) for the workflow and environment configuration.

### Workflow reference

#### Feature or standard fix

```bash
# Create branch
git checkout -b feat/my-new-feature # or fix/bug-description

# Work and commit...
git commit -m "implement core logic"

# Merge into main
# [Create GitHub PR -> Verify CI Pass (ci-pipeline.md) -> Squash and Merge -> Delete Branch]
```

#### Production hotfix

Hotfixes are treated as high-priority `fix/` branches.

```bash
# 1. Fix on main
git checkout main
git checkout -b fix/urgent-bug
# [Fix bug]
git commit -m "fix: resolve critical auth leak"

# 2. Merge (deploys automatically to staging on merge to main)
# [Create GitHub PR -> Verify CI Pass (ci-pipeline.md) -> Squash and Merge]

# 3. Tag to deploy to production (cd-pipeline.md)
git tag -a vX.Y.Z -m "Hotfix vX.Y.Z"
git push origin vX.Y.Z
```
