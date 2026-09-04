---
name: understanding-code
description: Use before implementing, changing, debugging, or reviewing any code in this project — finding a function or symbol, tracing callers/callees, understanding structure, confirming something exists (or doesn't), or answering "where is X defined" / "what calls Y" / "what does X call" / "does Z already do this". Triggers before any Grep/Read-based code exploration, not just multi-file ones — including a single lookup you think you already know the answer to.
---

# Understand the Codebase with codebase-memory-mcp

## Overview

This skill requires the `codebase-memory-mcp` server for structural code queries — a knowledge graph that answers "who calls X", "what does X call", "where is X defined" in ~500 tokens instead of grepping thousands of lines. Prefer (IMPORTANT) it over Grep/Read for any code question beyond text already on screen.

Two failures to avoid, both costly:

- **Skipping** — grepping blind or answering from memory, then missing a caller, an override, or a structural relationship the graph would have surfaced immediately.
- **Over-reading** — pulling in whole files or unrelated modules "to be safe" once you're in the tool, burning the token budget the graph was built to save.

The workflow below resolves both: query narrow and specific first, widen only if the answer isn't there.

## Before anything else: confirm the MCP is available

Look for `mcp__codebase-memory-mcp__*` tools in the current tool listing (`ToolSearch("select:mcp__codebase-memory-mcp__search_graph")` or the deferred-tools system reminder).

- **Available** → use it (workflow below).
- **Not available** → warn : "codebase-memory-mcp isn't installed in this session — code search will fall back to Grep/Read. Install: https://github.com/DeusData/codebase-memory-mcp" Then proceed with Grep/Read; don't block the task on it.

If we had not indexed the code yet in this session, `index_repository` will automatically be called first.

## The Discovery Procedure (graph-first)

1. `index_status` / `list_projects` — confirm the project is indexed and check `head_sha` against the working tree's current commit; if unindexed or behind, run `index_repository` (same `repo_path`, same `name`) to refresh before querying. A stale graph silently omits recent edits instead of erroring, so re-index rather than trust an old snapshot.
2. `search_graph(name_pattern="...")` — find a function/class/route by name.
3. `trace_path(function_name=..., direction="inbound"|"outbound"|"both")` — callers / callees / full call context.
4. `get_code_snippet(qualified_name="...")` — read exact source once located.
5. `get_architecture(aspects=[...])` — project structure/orientation questions.

Use Grep/Read directly for text in non-code files, configs, a single already-known file, or when the MCP is unavailable.

## Red Flags — STOP

These thoughts mean you're about to skip the tool. Each one means: run the query first, then proceed.

| Thought                                                | Reality                                                                                                         |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| "I'll just grep this real quick"                       | The graph answers it in fewer tokens and catches callers grep misses.                                           |
| "It's one function, I basically know where it lives"   | "Basically know" is a guess. Confirm it.                                                                        |
| "This is too small a lookup to bother with the tool"   | The tool call is cheaper than a wrong assumption downstream.                                                    |
| "I remember this codebase from earlier in the session" | Code changes underfoot; re-query rather than trust recall.                                                      |
| "Let me just read the file, it's faster"               | Reading a whole file to answer one structural question is the over-reading failure this tool exists to prevent. |
| "This task is about changing code, not searching it"   | Changing code requires understanding it first — that's this skill's trigger, not just explicit search requests. |

## Common Mistakes IMPORTANT

- Grepping first "to be quick" when the MCP is installed — it's slower and burns more context for anything beyond one file.
- Not checking `index_status` before querying a project that was never indexed.
