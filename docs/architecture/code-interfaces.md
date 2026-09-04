---
type: architecture
title: Code Interfaces
description: Which resource actions are exposed on their domain's code interface, and who calls through it.
tags: [architecture, ash, conventions, domain, testing]
timestamp: 2026-09-04T00:00:00Z
---

A resource action that outside code calls — another domain, a LiveView, a controller, a test asserting on behavior — is exposed as a function on the owning domain's code interface. The interface is defined in the same change that adds or changes the action; callers never reach into the resource directly.

## Which actions get an interface

Judge each action by whether code outside the resource has, or will have, a legitimate reason to call it directly.

| Action | Interface |
|---|---|
| Called by another domain, a LiveView, a controller, or a behavior test | **Yes** |
| Triggered only by another action's preparation or change | No |
| Internal lookup used by a library integration | No |
| Helper nothing outside the resource calls | No |

An interface on an internal-only action is a layer nothing uses.

## Callers go through the interface

The interface owns the argument mapping and the stable call shape, and is the single place a call changes later. Code that builds the changeset or query against the resource by hand bypasses all of that, and a broken or missing interface definition goes unnoticed because nothing exercises it.

**Tests of an externally-called action call it through the interface.** A test that goes to the resource directly cannot catch a wrong argument mapping or a missing definition. Building preconditions is different from testing behavior: setting up state with lower-level calls (seeding a related record, forcing an attribute the interface does not expose) is fine, as long as the thing under test goes through the real interface. See [testing.md](testing.md).
