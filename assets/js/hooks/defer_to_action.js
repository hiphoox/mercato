// Hides a pinned bar while the control it duplicates is on screen, so the two
// are never visible at once with the pinned one covering the other.
//
// The control is named by `data-defer-to`, holding its DOM id. A bar whose
// control is missing stays visible, which is the safe way to fail: the bar is
// the only way to act once the control has scrolled away.
//
// Sets a data attribute rather than styles, leaving the transition to CSS, and
// deliberately does not set phx-update="ignore" — the price and the label
// inside the bar are server-rendered and change.
export default {
  mounted() {
    this.watch()
  },

  // The control is re-rendered on a patch — going out of stock swaps its label
  // — and an observer holds the old element, so it is re-attached each time.
  updated() {
    this.watch()
  },

  destroyed() {
    this.observer?.disconnect()
  },

  watch() {
    this.observer?.disconnect()

    const action = document.getElementById(this.el.dataset.deferTo)

    if (!action) {
      this.el.dataset.deferred = "false"
      return
    }

    this.observer = new IntersectionObserver(
      ([entry]) => {
        this.el.dataset.deferred = entry.isIntersecting ? "true" : "false"
      },
      // The bar sits at the bottom of the viewport, so a control level with it
      // is behind it rather than in view. Discounting the bar's own height stops
      // the two swapping back and forth as one scrolls under the other.
      {rootMargin: `0px 0px -${this.el.offsetHeight}px 0px`}
    )

    this.observer.observe(action)
  }
}
