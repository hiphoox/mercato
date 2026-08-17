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
3. **Propose a plan as a simple bullet list** before writing any code. Keep it short — what will change, in what files, and why. Wait for the user to confirm before implementing.
4. **Implement test-first.** Write a failing test for the behavior, confirm it fails for the right reason, then write the minimal code to pass it — see Verify RED For The Right Reason below.
5. **Run the full test suite before declaring the work done**, not just the tests you added — a change can pass its own tests while breaking something else.
6. **Give the user something to manually verify the change with.** For backend/non-UI work, provide a ready-to-paste `iex -S mix` snippet exercising the new/changed behavior (not just "trust the tests"). For UI work, give concrete click-through steps (page, action, expected result). Do this before asking about commits — the user should be able to see the change work before deciding whether to commit it.
7. **Propose a commit list and ask for explicit permission before committing.** Never commit without the user saying so, even after a successful implementation. Group changes the way the user asks when they respond.

## Verify RED For The Right Reason

Before treating a failing test as proof the behavior isn't implemented yet, confirm *why* it's failing. A test that fails for an unrelated reason (a typo, a different bug, missing test setup) isn't RED for the behavior under test — it's just broken, and "fixing" it proves nothing.

The same applies in reverse: **a test that passes before you've written the implementation is a red flag, not a green light.** It means the test isn't actually exercising the behavior. Stop and investigate why it passed instead of moving on.

Concrete example from this session: a test asserting that sign-in is blocked for a banned account passed immediately, before any status-gating code existed. That should have been suspicious on its own. Investigating showed it was failing for an unrelated bug (a handle-regeneration issue on the sign-in upsert), not because status was actually being checked. The test was rewritten once the unrelated bug was fixed and the real RED (failing specifically on status) was confirmed.

## Manual Verification

Automated tests prove the code does what the test says — they don't prove the user can see it work. Before wrapping up, always hand the user something concrete to run or click through themselves:

- **Backend/non-UI change:** a self-contained `iex -S mix` snippet — real module names, real function calls, using data the snippet itself creates (don't assume fixtures exist). It should be copy-pasteable as-is and show an observable result (a return value, a printed struct, a raised error for a negative case).
- **UI change:** concrete steps — which page, what to click or type, what should appear. Start the dev server yourself and confirm the flow works before describing it, per this project's UI-testing conventions.

Skipping this and just citing "tests pass" is not equivalent — tests can pass while still testing the wrong thing (see Verify RED For The Right Reason above), and the user can't eyeball a test suite's intent the way they can eyeball a real run.

## Scope Creep

If implementation surfaces an unrelated bug or issue, don't silently fix it and don't silently ignore it — **surface it**. Tell the user what you found, why it's unrelated, and ask whether to fix it now, log it, or skip it. Let them decide; don't decide for them either way.

## Rabbit Holes

If debugging or investigating something isn't converging after a reasonable number of attempts (a flaky test, a framework quirk, unclear behavior), stop drilling. Report what's been found and propose a pragmatic path forward for approval, rather than continuing indefinitely on your own judgment.

## Destructive Git Operations

Never run a destructive or hard-to-reverse git operation (`reset --hard`, force-push, rewriting shared/pushed history, `checkout --`/`clean -f` that discards work) without asking first — this holds even mid-task, even if the user has approved other git actions earlier in the conversation.

## Quality Gates

After a change, run the project's lint/quality command and its test suite. Both should be clean — no open issues, not "no issues I introduced." If a pre-existing issue is discovered along the way, treat it as scope creep (see above): surface it and ask, don't leave it unmentioned.
