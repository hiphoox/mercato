// Drives the sidebar's drawer/rail state from the header's toggle button.
export default {
  mounted() {
    const root = document.documentElement

    // Asks CSS which regime is live instead of restating a breakpoint here. The
    // values come from --sidebar-mode in app.css, which is driven by the theme's
    // own --breakpoint-* tokens, so retuning the theme moves this too.
    const mode = () =>
      getComputedStyle(root).getPropertyValue("--sidebar-mode").trim()

    this.el.addEventListener("click", () => {
      const current = mode()

      if (current === "drawer") {
        const open = root.getAttribute("data-sidebar-drawer") !== "open"
        root.setAttribute("data-sidebar-drawer", open ? "open" : "closed")
        return
      }

      // The stored preference is deliberately tri-state. Absent means "whatever
      // this width defaults to", so the toggle has to resolve that default before
      // it can invert it — otherwise the first click on a small laptop, where the
      // rail is already showing, would appear to do nothing.
      const stored = root.getAttribute("data-sidebar-collapsed")
      const collapsed = stored === null ? current === "rail" : stored === "true"

      root.setAttribute("data-sidebar-collapsed", String(!collapsed))
      localStorage.setItem("mercato:sidebar-collapsed", String(!collapsed))
    })
  }
}
