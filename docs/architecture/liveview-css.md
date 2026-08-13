---
type: architecture
title: LiveView CSS
description: Tailwind CSS asset pipeline conventions for Phoenix LiveView.
tags: [liveview, css, tailwind]
timestamp: 2026-07-23T00:00:00Z
---

See also [liveview.md](liveview.md) for LiveView module conventions, [liveview-js.md](liveview-js.md) for JS interop, and [ui-guidelines.md](ui-guidelines.md) for design principles.

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

  ```css
  @import "tailwindcss" source(none);
  @source "../css";
  @source "../js";
  @source "../../lib/my_app_web";
  ```

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`
- **Never** use `@apply` when writing raw css
- **Always** manually write your own tailwind-based components instead of using daisyUI for a unique, world-class design
- Out of the box **only the app.js and app.css bundles are supported**
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts
  - You must import the vendor deps into app.js and app.css to use them
  - **Never write inline `<script>custom js</script>` tags within templates**
