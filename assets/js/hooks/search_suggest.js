// Completes what is typed in the header's search box, from the JSON:API the
// resources expose.
//
// Bound to the form rather than the input, because a suggestion acts on the
// whole form: a title fills the term and submits, a category sets the scope and
// submits, and a seller leaves for their profile instead.
//
// Three requests rather than one — the API serves resources, and these are
// three of them. They are issued together and rendered when all three land, so
// the panel never reflows as answers trickle in.
const DEBOUNCE_MS = 180
const MIN_TERM = 2
const ACCEPT = "application/vnd.api+json"

export default {
  mounted() {
    this.form = this.el
    this.input = this.el.querySelector("#app-search")
    this.scope = this.el.querySelector("#app-search-scope")
    this.panel = this.el.querySelector("#app-search-suggestions")
    this.rows = []
    this.active = -1

    this.onInput = () => this.schedule()
    this.onKeydown = (event) => this.keydown(event)
    this.onFocus = () => this.schedule()
    this.onOutside = (event) => {
      if (!this.el.contains(event.target)) this.close()
    }

    this.input.addEventListener("input", this.onInput)
    this.input.addEventListener("focus", this.onFocus)
    this.input.addEventListener("keydown", this.onKeydown)
    document.addEventListener("click", this.onOutside)

    // Picking a scope re-asks the question: the answers are scoped too.
    this.scope?.addEventListener("change", this.onInput)
  },

  destroyed() {
    clearTimeout(this.timer)
    this.pending?.abort()
    this.input?.removeEventListener("input", this.onInput)
    this.input?.removeEventListener("focus", this.onFocus)
    this.input?.removeEventListener("keydown", this.onKeydown)
    this.scope?.removeEventListener("change", this.onInput)
    document.removeEventListener("click", this.onOutside)
  },

  schedule() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.fetch(), DEBOUNCE_MS)
  },

  async fetch() {
    const term = this.input.value.trim()

    if (term.length < MIN_TERM) return this.close()

    // The in-flight request is abandoned rather than raced: without this a slow
    // early answer can land after a fast late one and overwrite it.
    this.pending?.abort()
    this.pending = new AbortController()

    const base = this.el.dataset.suggestPath
    const scope = this.scope?.value || ""
    const query = (path, extra = true) => {
      const params = new URLSearchParams({query: term})
      if (extra && scope) params.set("category_slug", scope)
      return `${base}${path}?${params}`
    }

    try {
      const [titles, categories, sellers] = await Promise.all([
        this.read(query("/listings/suggest")),
        // Nothing to offer once a scope is set: the selector already says which
        // one is in force.
        scope ? [] : this.read(query("/categories/suggest", false)),
        this.read(query("/sellers/suggest"))
      ])

      this.render(titles, categories, sellers)
    } catch (error) {
      // An aborted request is the expected way a keystroke supersedes another.
      if (error.name !== "AbortError") this.close()
    }
  },

  async read(url) {
    const response = await fetch(url, {
      signal: this.pending.signal,
      headers: {accept: ACCEPT}
    })

    if (!response.ok) throw new Error(`suggest failed: ${response.status}`)

    const body = await response.json()

    return (body.data || []).map((row) => row.attributes)
  },

  render(titles, categories, sellers) {
    const sellerPath = this.el.dataset.sellerPath
    const labels = this.el.dataset

    this.rows = [
      ...this.group(labels.labelListings, titles, (row) => ({
        text: row.title,
        act: () => this.searchFor(row.title)
      })),
      ...this.group(labels.labelCategories, categories, (row) => ({
        text: row.name,
        act: () => this.browseCategory(row.slug)
      })),
      ...this.group(labels.labelSellers, sellers, (row) => ({
        text: `@${row.handle}`,
        // The handle is the suggestion; the name says why it matched.
        hint: [row.first_name, row.last_name].filter(Boolean).join(" "),
        act: () => {
          window.location.href = `${sellerPath}/${row.handle}`
        }
      }))
    ]

    if (this.rows.length === 0) return this.close()

    this.panel.replaceChildren(...this.rows.map((row, index) => this.node(row, index)))
    this.panel.hidden = false
    this.input.setAttribute("aria-expanded", "true")
    this.activate(-1)
  },

  group(label, rows, toRow) {
    if (rows.length === 0) return []

    return [{header: label}, ...rows.map(toRow)]
  },

  node(row, index) {
    const li = document.createElement("li")

    if (row.header) {
      li.textContent = row.header
      li.className = "px-3.5 pt-2 pb-1 text-caption-md font-semibold text-ink-500 select-none"
      return li
    }

    li.id = `app-search-suggestion-${index}`
    li.setAttribute("role", "option")
    li.setAttribute("aria-selected", "false")
    li.className =
      "flex items-baseline gap-2 px-3.5 h-10 cursor-pointer text-body-md " +
      "text-ink-900 dark:text-white hover:bg-bg-2 dark:hover:bg-ink-700"

    const text = document.createElement("span")
    text.className = "truncate"
    text.textContent = row.text
    li.appendChild(text)

    if (row.hint) {
      const hint = document.createElement("span")
      hint.className = "truncate text-body-sm text-ink-500"
      hint.textContent = row.hint
      li.appendChild(hint)
    }

    // mousedown, not click: the input blurs first on a click and the panel
    // would already be closing.
    li.addEventListener("mousedown", (event) => {
      event.preventDefault()
      row.act()
    })

    return li
  },

  keydown(event) {
    if (event.key === "Escape") return this.close()

    if (this.panel.hidden) return

    const selectable = this.rows
      .map((row, index) => (row.header ? null : index))
      .filter((index) => index !== null)

    if (selectable.length === 0) return

    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()

      const step = event.key === "ArrowDown" ? 1 : -1
      const at = selectable.indexOf(this.active)
      const next = at === -1 ? (step === 1 ? 0 : selectable.length - 1) : at + step

      // Wraps, so holding a key never dead-ends at either end of a short list.
      const wrapped = (next + selectable.length) % selectable.length

      return this.activate(selectable[wrapped])
    }

    if (event.key === "Enter" && this.active !== -1) {
      event.preventDefault()
      this.rows[this.active].act()
    }
  },

  activate(index) {
    this.active = index

    this.panel.querySelectorAll('[role="option"]').forEach((node) => {
      const selected = node.id === `app-search-suggestion-${index}`

      node.setAttribute("aria-selected", String(selected))
      node.classList.toggle("bg-bg-2", selected)
      node.classList.toggle("dark:bg-ink-700", selected)
    })

    if (index === -1) {
      this.input.removeAttribute("aria-activedescendant")
    } else {
      this.input.setAttribute("aria-activedescendant", `app-search-suggestion-${index}`)
    }
  },

  // A completion goes through the same GET the form would have submitted by
  // hand, so a suggestion and a typed search are one path on the server.
  searchFor(term) {
    this.input.value = term
    this.form.submit()
  },

  browseCategory(slug) {
    if (this.scope) this.scope.value = slug
    this.input.value = ""
    this.form.submit()
  },

  close() {
    this.panel.hidden = true
    this.panel.replaceChildren()
    this.rows = []
    this.active = -1
    this.input.setAttribute("aria-expanded", "false")
    this.input.removeAttribute("aria-activedescendant")
  }
}
