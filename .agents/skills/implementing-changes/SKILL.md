---
name: implementing-changes
description: Use before and during any task that changes code, schema, or docs in this repo — implementing a feature, fixing a bug, or picking up a todo item. Governs the workflow from clarifying questions through implementation to the commit proposal.
---

# Working on Changes

A fixed sequence for turning a task into a change. The user stays in control of scope, of what gets built, and of when anything is committed. Applies to every change — bug fix, feature, todo item — regardless of size.

Project conventions (code style, architecture, framework usage, testing rules, quality commands) live in the docs, not here. Whenever a step says "the docs", find the governing file through `reading-docs`; never rely on memory of a past session.

## Workflow

1. **Read the docs.** Invoke `reading-docs` to load the docs governing the task's concerns.
2. **Understand the code.** Invoke `understanding-code` to locate what the change touches, its callers, and what already exists.
3. **Grill the user.** Ask about every unclear part — scope, design choices, edge cases. Make it interactive: use the harness's question/form tool when one exists, one topic per question; otherwise a numbered list. Don't guess.
4. **Propose a plan.** Extremely concise — sacrifice grammar for concision. Bullets or numbered list. Every item points at the file (and line, where known) it refers to.
5. **End the plan with unresolved questions**, if any. Wait for approval.
6. **Implement**, showing progress as a live todo list when the harness has one (one item per plan step).
   - 6.1 **Sync docs in the same change.** Every implementation updates the docs it affects, or creates new ones, via `writing-docs`. No rotten docs.
7. **TDD.** Write the failing test first. Verify RED for the right reason — the test must fail *because the behavior is missing*, not from a typo, a different bug, or broken setup. A test that passes before the implementation exists is a red flag: stop and find out why. Then write the minimal code to make it GREEN.
8. **Follow the code and architecture guidelines** from the docs — conventions, layering, data-layer support, interface rules.
9. **Run the full test suite and the quality checks** (commands are in the docs) before declaring work done. Both clean — not "clean except what I didn't introduce".
10. **Provide a manual QA plan for the developer** to follow themselves after the work is done. Concise: numbered steps, each with an expected result. Backend: a ready-to-paste snippet for the project's REPL that creates its own data and shows an observable result. UI: page → action → what should appear. "Tests pass" is not a substitute.

## Don'ts

- **Don't commit, push, or open a PR on your own.** Propose a commit list and wait for explicit approval, every time.
- **Don't run destructive git operations** (`reset --hard`, force-push, history rewrites, `checkout --`/`clean -f` that discard work) without asking first — even mid-task, even if other git actions were approved earlier.
- **Don't excuse anything as "pre-existing".** After the change, everything is green — tests, quality checks, compiler and test warnings. A warning or failure you found is yours to fix in this change, unless the user says otherwise.
- **Don't go down rabbit holes.** If debugging or investigating isn't converging after max 3 attempts, stop. Report what was found and propose a pragmatic path to resolve.
- **Don't go out of scope.** If implementation surfaces an unrelated bug or issue, don't silently fix it and don't silently ignore it — surface it. Say what was found, why it's unrelated, and ask whether to fix it now, log it, or skip it. The user decides.
