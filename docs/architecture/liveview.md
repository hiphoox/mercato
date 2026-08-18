---
type: architecture
title: LiveView
description: Conventions for Phoenix LiveView modules — layouts, scope, and component structure.
tags: [liveview, elixir, phoenix]
timestamp: 2026-08-18T00:00:00Z
---

## Component structure

- **LiveView pages** live in `live/<feature>/*_live.ex` — one folder per feature domain.
- **Reusable components** — generic, usable by any feature regardless of domain (buttons, inputs, cards, links) — live in `components/core_components.ex`.
- **Live components and feature-specific function components** — used by only one feature, whether stateful (`use ... :live_component`) or not — live colocated in that feature's `live/<feature>/` folder, next to the LiveView that owns them. Stateful vs. not doesn't change where the module lives, only what it `use`s.
- The line between "feature-specific" and "reusable" is scope, not statefulness: a component stays in `live/<feature>/` as long as only that feature uses it. The moment a second feature would reuse it as-is, promote it to `components/core_components.ex`.

## Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">`) class with your own values, no default classes are inherited, so your custom classes must fully style the input

## Phoenix LiveView guidelines

- **Never** use the deprecated `live_redirect` and `live_patch` functions, instead **always** use the `<.link navigate={href}>` and `<.link patch={href}>` in templates, and `push_navigate` and `push_patch` functions LiveViews
- **Avoid LiveComponent's** unless you have a strong, specific need for them
- LiveViews should be named like `AppWeb.WeatherLive`, with a `Live` suffix. When you go to add LiveView routes to the router, the default `:browser` scope is **already aliased** with the `AppWeb` module, so you can just do `live "/weather", WeatherLive`

See also:

- [liveview-streams.md](liveview-streams.md) when working with collections.
- [heex-templates.md](heex-templates.md) when creating/editing on HEEx templates.
- [liveview-css.md](liveview-css.md) when creating/editing the Tailwind/CSS asset pipeline.
- [liveview-js.md](liveview-js.md) when creating/editing JS hooks or client/server events.
- [coding-standards.md](coding-standards.md)
- [liveview-testing.md](liveview-testing.md) when creating/editin liveview tests.
