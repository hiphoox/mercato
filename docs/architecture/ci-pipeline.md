---
type: architecture
title: CI Pipeline
description: Quality gates, CI commands, and verification requirements.
tags: [ci, github-actions, quality-gates]
timestamp: 2026-07-23T00:00:00Z
---

The CI pipeline is the primary quality gate for the project. It automates verification of every contribution to catch regressions and enforce a consistent standard of code quality before merging.

## Workflow execution

The CI pipeline is implemented using **GitHub Actions** and is triggered automatically under the following conditions:

- **Pull requests:** Every pull request targeting any branch.
- **Pushes to `main`:** Every merge or push directly to the `main` branch.

## Quality gates

The pipeline executes a series of checks. A failure in any of these steps blocks the merge process.

### 1. Compilation

The codebase is compiled to ensure there are no syntax errors or type mismatches.

- **Command:** `mix compile --warnings-as-errors`
- **Goal:** Zero warnings in the codebase, preventing the accumulation of technical debt.

### 2. Formatting

Ensures that the code adheres to the project's style guidelines.

- **Command:** `mix format --check-formatted`
- **Goal:** A consistent visual style across the project.

### 3. Static analysis

Performs deep analysis of the code to identify smells, complexity issues, and common pitfalls.

- **Command:** `mix credo --strict`
- **Goal:** High-quality coding patterns, free of "code smells."

### 4. Test suite

Executes the full suite of automated tests to ensure functional correctness.

- **Command:** `mix test`
- **Goal:** Regression-free, correctly behaving business logic.

## Governance & deployment

Branching and merge policies are defined in [git-strategy.md](git-strategy.md). Continuous Deployment (CD) is a separate concern — see [cd-pipeline.md](cd-pipeline.md) for how verified code is deployed to Fly.io.
