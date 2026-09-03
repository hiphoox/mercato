defmodule MercatoWeb.UI.Sheet do
  @moduledoc """
  A panel that comes in from an edge to hold what does not fit on the page.

  One markup tree, switched in CSS: a drawer down the right from `md` up, and a
  bottom sheet below it, where a thumb reaches the bottom of the screen more
  easily than the side. Open state is client-only by default, so a sheet costs
  no assign and no re-render.

  A sheet holding a form is the exception: whether it stays open depends on
  whether the save was taken, which only the server knows. Such a sheet is
  given `open` and the server decides, so a refused save keeps the form and its
  errors on screen instead of closing over them.

      <.button phx-click={show_sheet("filters")}>All filters</.button>

      <.sheet id="filters" title="All filters">
        <p>Everything that did not fit on the bar.</p>
        <:footer><.button size="md">Apply</.button></:footer>
      </.sheet>
  """
  use MercatoWeb, :html

  @doc """
  Renders the sheet, closed.

  It is rendered wherever it is written but positioned against the viewport, so
  a scrolling ancestor — the app layout's main column is one — cannot clip it.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true, doc: "the heading, and the dialog's accessible name"
  attr :class, :any, default: nil, doc: "classes for the panel"

  attr :open, :boolean,
    default: false,
    doc: "renders it already open, for a sheet whose state the server owns rather than the client"

  attr :on_close, JS,
    default: %JS{},
    doc: "what else closing does — how a server-owned sheet is told it has been closed"

  attr :rest, :global

  slot :inner_block, required: true
  slot :footer, doc: "the actions that close the sheet — apply, clear"

  def sheet(assigns) do
    ~H"""
    <div
      id={@id}
      class={
        [
          # The `hidden` class, never the `hidden` attribute — preflight's
          # `display:none !important` would beat the display JS.show sets.
          if(@open, do: "flex", else: "hidden"),
          "fixed inset-0 z-80 items-end justify-stretch md:items-stretch md:justify-end"
        ]
      }
      phx-window-keydown={hide_sheet(@on_close, @id)}
      phx-key="escape"
      {@rest}
    >
      <div
        id={"#{@id}-scrim"}
        aria-hidden="true"
        phx-click={hide_sheet(@on_close, @id)}
        class="absolute inset-0 bg-ink-900/45"
      >
      </div>

      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        class={[
          "relative flex flex-col w-full max-h-[86%] rounded-t-lg",
          "md:w-105 md:max-w-full md:max-h-none md:rounded-none",
          "bg-bg dark:bg-ink-900 shadow-lg",
          @class
        ]}
      >
        <div class="flex items-center justify-between gap-3 px-5 py-4 border-b border-ink-100 dark:border-ink-700">
          <h2 id={"#{@id}-title"} class="text-title-lg font-bold text-ink-900 dark:text-white">
            {@title}
          </h2>
          <button
            type="button"
            id={"#{@id}-close"}
            aria-label={gettext("Close")}
            phx-click={hide_sheet(@on_close, @id)}
            class={[
              "flex items-center justify-center size-11 flex-none rounded-md cursor-pointer",
              "text-ink-500 hover:bg-ink-100 hover:text-ink-900",
              "dark:hover:bg-ink-700 dark:hover:text-white",
              "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
            ]}
          >
            <.icon name="hero-x-mark" aria-hidden="true" class="size-5" />
          </button>
        </div>

        <div class="flex-1 min-h-0 overflow-y-auto p-5 flex flex-col gap-7">
          {render_slot(@inner_block)}
        </div>

        <div
          :if={@footer != []}
          id={"#{@id}-footer"}
          class="flex items-center gap-3 px-5 py-4 border-t border-ink-100 dark:border-ink-700"
        >
          {render_slot(@footer)}
        </div>
      </div>
    </div>
    """
  end

  @doc "The command that opens a sheet, for the control that offers it."
  def show_sheet(js \\ %JS{}, id) do
    # display: "flex" — the wrapper pins the panel to an edge with flex
    # alignment; revealed as display:block it would fill the viewport instead.
    JS.show(js, to: "##{id}", display: "flex")
  end

  @doc "The command that closes a sheet."
  def hide_sheet(js \\ %JS{}, id), do: JS.hide(js, to: "##{id}")
end
