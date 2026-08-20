---
type: architecture
title: Ash Declarative Conventions
description: Principles for writing Ash resources as declarations, not programs.
tags: [architecture, ash, conventions]
timestamp: 2026-08-20T00:00:00Z
resource: https://ash.hexdocs.pm/design-principles.html
---

Ash's own design principles state that "all behavior is driven by explicit, static declarations" — a resource is meant to read as a specification other code acts on, not as a program. Every DSL section (`attributes`, `actions`, `policies`, ...) exists so a rule is *declared once, in the place that owns it* — not re-derived by hand wherever it's needed.

Two hand-rolled implementations of the same rule look identical today and quietly diverge tomorrow, once one of them picks up a tweak the other doesn't. A declarative resource sidesteps that by [extracting the data, not abstracting the code](https://www.zachdaniel.dev/p/incremental-declarative-design): a declaration read in two places is the same fact twice, not two copies of logic that can drift apart.

## Prefer the DSL's own derivation over restating it

Where the DSL can derive a value from something already declared elsewhere on the resource, let it — don't restate that value by hand. `accept [:field]` deriving an argument's type/constraints/`allow_nil?` from the attribute it fills is one instance of this; the same principle applies anywhere a DSL option offers to infer from existing declarations instead of taking them as separate input. Restate it explicitly only when the two truly need to diverge (e.g. an action requiring a value stricter than the attribute allows, or the value needing transformation before it lands on the attribute) — and note *why* they diverge, so the divergence reads as intentional.

## Prefer a built-in over a custom module

`Ash.Resource.Change.Builtins`, `Ash.Resource.Validation.Builtins`, and `Ash.Policy.Check.Builtins` cover the common cases — setting a static or computed attribute, confirming two arguments match, relating the actor, and more. A custom module earns its place only when the logic can't be expressed as one of these — a database lookup, a third-party call, multi-step branching.

## Keep each concern in its own DSL section

Authorization belongs in `policies`, expressed through checks — not as `if`/`case` branches inside a `change` or `validation`. Validity belongs in `validations`, not folded into a `change`. A resource's rules should each be findable by which section they live in, not buried inside another section's logic. See [principles.md → OCP](principles.md#ocp--openclosed) for the related rule on extending a resource by adding a section entry rather than branching inside an existing one.

## Keep a data-layer quirk out of the resource

Where a data layer needs a different expression than another would for the same meaning, that difference belongs in a custom expression with one clause per data layer — not spelled out in the filter of every action that needs it. The resource states the intent and the expression supplies each backend's spelling. See [data-layer-expressions.md](data-layer-expressions.md) for the divergences this project has hit and how to recognise a new one.
