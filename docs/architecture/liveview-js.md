---
type: architecture
title: LiveView JS
description: LiveView JavaScript interop — hooks and client/server events.
tags: [liveview, javascript, hooks]
timestamp: 2026-08-21T00:00:00Z
---

See also [liveview.md](liveview.md) for LiveView module conventions and [liveview-css.md](liveview-css.md) for the Tailwind/CSS asset pipeline.

## Where hooks live

Every JS hook is its own file under `assets/js/hooks/`, named in snake_case after the hook it exports, with the hook object as the default export:

```javascript
// assets/js/hooks/phone_number.js
export default {
  mounted() {
    this.el.addEventListener("input", () => { ... })
  }
}
```

`assets/js/hooks/index.js` is the single registry — it imports each hook file and exports them keyed by the name templates use:

```javascript
import PhoneNumber from "./phone_number"

export default {PhoneNumber}
```

That object is handed to the `LiveSocket` constructor in `assets/js/app.js`, and the template refers to the hook by that key:

```heex
<input type="text" id="user-phone-number" phx-hook="PhoneNumber" />
```

Colocated hooks — a `<script :type={Phoenix.LiveView.ColocatedHook}>` block inside a template — are not used here: behavior belongs in a JS file where it can be read, diffed, and found by name. Raw `<script>` tags in HEEx are incompatible with LiveView and are never an option either.

## Rules for every hook

- A hook needs a unique DOM id on the same element, or the compiler raises.
- A hook that manages its own DOM subtree must also set `phx-update="ignore"`, so a patch does not overwrite what the hook wrote. A hook that only reads the element or sets styles on it must not — the server keeps rendering the contents.
- Each hook file opens with a comment saying what it does to the element it is attached to.

## Pushing events between client and server

Use LiveView's `push_event/3` when you need to push events/data to the client for a phx-hook to handle. **Always** return or rebind the socket on `push_event/3` when pushing events:

```elixir
# re-bind socket so we maintain event state to be pushed
socket = push_event(socket, "my_event", %{...})

# or return the modified socket directly:
def handle_event("some_event", _, socket) do
  {:noreply, push_event(socket, "my_event", %{...})}
end
```

Pushed events can then be picked up in a JS hook with `this.handleEvent`:

```javascript
mounted() {
  this.handleEvent("my_event", data => console.log("from server:", data));
}
```

Clients can also push an event to the server and receive a reply with `this.pushEvent`:

```javascript
mounted() {
  this.el.addEventListener("click", e => {
    this.pushEvent("my_event", { one: 1 }, reply => console.log("got reply from server:", reply));
  })
}
```

Where the server handled it via:

```elixir
def handle_event("my_event", %{"one" => 1}, socket) do
  {:reply, %{two: 2}, socket}
end
```
