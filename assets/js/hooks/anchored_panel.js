// Positions a popup panel against its trigger in the viewport rather than in
// the document flow, so a scrolling or clipping ancestor cannot cut it off.
//
// Deliberately does not set phx-update="ignore": the rows inside the panel are
// server-rendered and change (a menu of statuses loses the one just applied),
// so the hook owns the panel's position and nothing else.
export default {
  mounted() {
    this.anchor = document.getElementById(this.el.dataset.anchor)
    this.reposition = () => this.position()
    this.open = false

    // Only the closest phx-click binding fires, so a click on an item never
    // reaches a handler on the panel. The panel publishes the close command
    // and the hook decides when to run it.
    //
    // Run it through the JS command machinery rather than setting display
    // directly: the open is registered as a *sticky* operation that LiveView
    // replays after every patch, and only the matching command clears it.
    this.el.addEventListener("click", (event) => {
      if (event.target.closest("a, button")) {
        this.js().exec(this.el.dataset.close)
      }
    })

    // The panel is opened by a JS.toggle on the trigger, which flips the
    // inline display and emits no event — the style attribute changing is
    // the only signal that it became visible.
    this.observer = new MutationObserver(() => this.sync())
    this.observer.observe(this.el, {attributes: true, attributeFilter: ["style"]})
    this.sync()
  },

  updated() {
    // A patch replays the sticky open, restoring display but not the
    // coordinates, so an already-open panel has to be measured again.
    this.sync()
    if (this.open) { this.position() }
  },

  destroyed() {
    this.observer.disconnect()
    this.unbind()
  },

  sync() {
    const display = this.el.style.display
    const open = display !== "" && display !== "none"
    if (open === this.open) { return }

    this.open = open
    if (open) {
      this.bind()
      this.position()
    } else {
      this.unbind()
    }
  },

  bind() {
    window.addEventListener("scroll", this.reposition, true)
    window.addEventListener("resize", this.reposition)
  },

  unbind() {
    window.removeEventListener("scroll", this.reposition, true)
    window.removeEventListener("resize", this.reposition)
  },

  position() {
    if (!this.anchor) { return }

    const gap = 8
    const rect = this.anchor.getBoundingClientRect()
    const width = this.el.offsetWidth
    const height = this.el.offsetHeight

    // Open upward only when there is room up there; a panel taller than the
    // viewport has nowhere better to go than its natural place below.
    const below = rect.bottom + gap
    const flip = below + height > window.innerHeight && rect.top - gap - height > 0

    // Aligned to whichever of the trigger's edges the caller named, then held
    // inside the viewport so a trigger near either edge cannot push the panel
    // off-screen.
    const aligned = this.el.dataset.align === "left" ? rect.left : rect.right - width
    const left = Math.max(gap, Math.min(aligned, window.innerWidth - width - gap))

    Object.assign(this.el.style, {
      position: "fixed",
      top: `${flip ? rect.top - gap - height : below}px`,
      left: `${left}px`,
      right: "auto",
      bottom: "auto",
    })
  },
}
