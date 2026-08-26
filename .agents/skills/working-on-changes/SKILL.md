---
name: working-on-changes
description: Use before and during any task that changes code, schema, or docs in this repo — implementing a feature, fixing a bug, or picking up a todo item. Governs the workflow from clarifying questions through implementation to commit.
---

# Working on Changes

## Overview

A fixed sequence for turning a task into a change, so the user stays in control of scope and of when anything is committed. Applies to bug fixes, features, and todo items alike — not just large or architectural work.

## Procedure

1. **Ask clarifying questions if needed.** Don't guess at ambiguous scope or an unstated design choice — ask, one question at a time if there are several.
2. **Always read the docs and code before proposing anything.** Use `read-docs` and `understand-code` per their own trigger conditions — don't rely on memory of an earlier turn or an earlier session.
3. **Propose a plan as a simple bullet list** before writing any code. Keep it short — what will change, in what files, and why. Wait for the user to confirm before implementing and then do the tasks as TODO items.
4. **Implement test-first. (TDD)** Write a failing test for the behavior, confirm it fails for the right reason, then write the minimal code to pass it — see Verify RED For The Right Reason below. If the change adds or touches an action meant to be called from outside the resource, give it a public interface in the same change — see Externally-Called Actions Get A Public Interface below.
5. **Run the full test suite before declaring the work done**, not just the tests you added — a change can pass its own tests while breaking something else.
6. **Give the user something to manually verify the change with.** For backend/non-UI work, provide a ready-to-paste `iex -S mix` snippet exercising the new/changed behavior (not just "trust the tests"). For UI work, give concrete click-through steps (page, action, expected result). Do this before asking about commits — the user should be able to see the change work before deciding whether to commit it.
7. **Propose a commit list and ask for explicit permission before committing.** Never commit without the user saying so, even after a successful implementation. Group changes the way the user asks when they respond.

## Verify RED For The Right Reason

Before treating a failing test as proof the behavior isn't implemented yet, confirm _why_ it's failing. A test that fails for an unrelated reason (a typo, a different bug, missing test setup) isn't RED for the behavior under test — it's just broken, and "fixing" it proves nothing.

The same applies in reverse: **a test that passes before you've written the implementation is a red flag, not a green light.** It means the test isn't actually exercising the behavior. Stop and investigate why it passed instead of moving on.

Concrete example from this session: a test asserting that sign-in is blocked for a banned account passed immediately, before any status-gating code existed. That should have been suspicious on its own. Investigating showed it was failing for an unrelated bug (a handle-regeneration issue on the sign-in upsert), not because status was actually being checked. The test was rewritten once the unrelated bug was fixed and the real RED (failing specifically on status) was confirmed.

## Manual Verification

Automated tests prove the code does what the test says — they don't prove the user can see it work. Before wrapping up, always hand the user something concrete to run or click through themselves:

- **Backend/non-UI change:** a self-contained `iex -S mix` snippet — real module names, real function calls, using data the snippet itself creates (don't assume fixtures exist). It should be copy-pasteable as-is and show an observable result (a return value, a printed struct, a raised error for a negative case).
- **UI change:** concrete steps — which page, what to click or type, what should appear. Start the dev server yourself and confirm the flow works before describing it, per this project's UI-testing conventions.

Skipping this and just citing "tests pass" is not equivalent — tests can pass while still testing the wrong thing (see Verify RED For The Right Reason above), and the user can't eyeball a test suite's intent the way they can eyeball a real run.

## Externally-Called Actions Get A Public Interface

This applies to actions meant to be invoked from _outside_ the resource — by another context/domain, a LiveView, a controller, a test asserting on real behavior. It does not apply to actions that exist purely as internal implementation details: an action only ever triggered by a `Preparation`/`Change` on another action, an internal token/subject lookup used by a library integration, a helper action nothing outside the resource calls. Forcing an interface onto those adds a layer nothing uses — judge each action by whether outside code has (or will have) a legitimate reason to call it directly, not by a blanket rule.

When an action _does_ meet that bar, define its public interface in the same change you add or change the action — don't leave callers (or tests) to reach into the underlying resource directly. In this project that means a matching `define` on `Mercato.Accounts` (or the owning domain).

This isn't just a testing rule. Code that calls the resource directly instead of through the interface has the same problem tests do: it bypasses whatever the interface layer is responsible for (arg mapping, a stable call shape, a single place to change later) and nothing catches a broken or missing interface definition, because nothing exercises it.

**Consequently, tests of an externally-called action must call it through the interface**, not through the resource directly — a test that bypasses the interface can't catch a wrong `args:` mapping or a missing `define`. Building fixtures or preconditions is different from testing behavior: it's fine to set up test state with lower-level/direct calls (seeding a related record, forcing an attribute the interface doesn't expose) as long as the thing actually under test goes through the real interface.

Concrete example from this session: `change_status` and `update_handle` are `User` actions callers outside the resource need (an admin action, a self-service profile action) — but neither had a matching `define` on `Mercato.Accounts`. Tests then had no interface to call, so they used `Ash.Changeset.for_update(:change_status, ...) |> Ash.update!()` directly. Fixing it meant two things: adding `define :change_status, ...` (and the others) to the domain, _and_ rewriting the tests to call `Accounts.change_status/4` instead — the missing interface was the root cause, the direct-resource test was a symptom of it. By contrast, `bump_last_active_at` is only ever triggered internally by a sign-in `Preparation` — it doesn't need one.

## Scope Creep

If implementation surfaces an unrelated bug or issue, don't silently fix it and don't silently ignore it — **surface it**. Tell the user what you found, why it's unrelated, and ask whether to fix it now, log it, or skip it. Let them decide; don't decide for them either way.

## Rabbit Holes

If debugging or investigating something isn't converging after a reasonable number of attempts (a flaky test, a framework quirk, unclear behavior), stop drilling. Report what's been found and propose a pragmatic path forward for approval, rather than continuing indefinitely on your own judgment.

## Destructive Git Operations

Never run a destructive or hard-to-reverse git operation (`reset --hard`, force-push, rewriting shared/pushed history, `checkout --`/`clean -f` that discards work) without asking first — this holds even mid-task, even if the user has approved other git actions earlier in the conversation.

## Prefer Ash's Declarative DSL

Ash's distinguishing feature is that behavior is _declared_, not programmed. Before writing a custom `Change`, `Validation`, `Preparation`, `Check`, or a plain function that queries a resource, check whether the DSL already expresses it:

- **A builtin before a custom module.** `Ash.Resource.Change.Builtins`, `Ash.Resource.Validation.Builtins`, and `Ash.Policy.Check.Builtins` cover most cases, and they compose — `negate(attribute_in(:handle, @reserved))` replaces a hand-written validation module outright. A custom module earns its place only when the logic genuinely can't be expressed as one: a DB lookup, a third-party call, multi-step branching.
- **Let the DSL derive rather than restating.** `accept [:field]` infers type, constraints, and `allow_nil?` from the attribute. Restate a value by hand only when it must truly diverge, and say why in a comment.
- **Reach the data through declared relationships.** A `many_to_many` or `has_many` plus `exists/2` in an expression beats a hand-built `Ash.Query` inside a change or check.
- **Go through the domain's code interface**, not `Ash.read/2`/`Ash.get/2` in a bare function. If a resource needs a lookup, that lookup is an action with a `define`.
- **Hoist a change repeated across actions** into a top-level `changes do ... on: [:create] end` block, so the rule is declared once.
- **Each concern in its own section.** Authorization goes in `policies`, validity in `validations` — not as `if`/`case` branches inside a `change`.

**Check the data layer supports it before designing around it.** AshSqlite is not AshPostgres — `deps/ash_sqlite/lib/data_layer.ex`'s `can?/2` clauses are the authoritative list. Notably it has **no aggregate support at all** (`aggregates do` blocks, aggregate filter/sort/relationship), and no transactions, lateral joins, or `distinct`. Expression calculations, `exists/2`, filter expressions, and query-time counts _are_ supported. A design that leans on an unsupported feature fails at compile or runtime, not review — verify against `can?/2` first. See [data-layer-expressions.md](../../../docs/architecture/data-layer-expressions.md).

Full rationale in [ash-declarative-conventions.md](../../../docs/architecture/ash-declarative-conventions.md).

## Quality Gates

After a change, run the project's lint/quality command and its test suite. Both should be clean — no open issues, not "no issues I introduced." If a pre-existing issue is discovered along the way, treat it as scope creep (see above): surface it and ask, don't leave it unmentioned.
