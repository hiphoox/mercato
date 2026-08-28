defmodule MercatoWeb.UI.Popover do
  @moduledoc """
  A panel that hangs off a trigger and is dismissed by clicking away or by Escape.

  The disclosure itself, with nothing said about what is inside it: an account
  menu, a list of sort options and a pair of price fields are the same object at
  three moments, and only their `role` tells them apart. Open/closed state is
  held entirely on the client, so no LiveView tracks it.

      <.popover id="sort" align="left">
        <:trigger>Newest</:trigger>
        <.menu_item label="Newest" role="menuitemradio" />
      </.popover>
  """
  use MercatoWeb, :html

  @doc """
  Renders the popover.

  The panel is named by its trigger unless given a `label` of its own, which is
  what a trigger reading "€80–€600" needs — the value is not the name of the
  thing being set.
  """
  attr :id, :string, required: true, doc: "unique id; the trigger and panel derive theirs from it"

  attr :role, :string,
    default: "menu",
    values: ~w(menu dialog),
    doc: "`menu` for a list of choices, `dialog` for anything a caller has to fill in"

  attr :align, :string,
    default: "right",
    values: ~w(left right),
    doc: "which of the trigger's edges the panel hangs off"

  attr :label, :string,
    default: nil,
    doc: "names the panel when the trigger's text does not; defaults to the trigger"

  attr :class, :any, default: nil, doc: "classes for the panel"

  attr :trigger_class, :any,
    default: "bg-bg dark:bg-ink-700 shadow-sm transition-[filter] hover:brightness-97",
    doc: """
    The trigger's chrome, replacing the default raised surface outright rather
    than adding to it — a Tailwind utility passed alongside a conflicting one
    resolves by stylesheet order, not attribute order, so the two cannot be
    layered.
    """

  attr :rest, :global

  slot :trigger, required: true, doc: "the button's contents"
  slot :inner_block, required: true, doc: "the panel's contents"

  def popover(assigns) do
    ~H"""
    <%!-- click-away lives on the wrapper, not the panel: the trigger sits outside
          the panel, so a panel-scoped handler would fire on the very click that
          opens it and close it again in the same event. --%>
    <div class="relative" phx-click-away={close_popover(@id)} {@rest}>
      <button
        type="button"
        id={"#{@id}-trigger"}
        aria-haspopup={@role}
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={open_popover(@id)}
        class={[
          "flex items-center gap-2 rounded-md cursor-pointer",
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100",
          @trigger_class
        ]}
      >
        {render_slot(@trigger)}
      </button>

      <%!-- AnchoredPanel (assets/js/hooks/anchored_panel.js) only positions the
            panel; it deliberately does not take the DOM over with
            phx-update="ignore", because the rows inside are server-rendered and
            change (a menu of statuses loses the one just applied). --%>
      <div
        id={"#{@id}-panel"}
        role={@role}
        aria-label={@label}
        aria-labelledby={is_nil(@label) && "#{@id}-trigger"}
        phx-hook="AnchoredPanel"
        data-anchor={"#{@id}-trigger"}
        data-align={@align}
        data-close={close_popover(@id)}
        phx-window-keydown={close_popover(@id)}
        phx-key="escape"
        class={
          [
            # The `hidden` class, never the `hidden` attribute: Tailwind's preflight marks
            # [hidden] as `display:none !important`, which beats the inline display that
            # JS.toggle sets and would leave the panel permanently invisible.
            "hidden",
            "absolute top-[calc(100%+8px)] z-60 p-2",
            @align == "right" && "right-0",
            @align == "left" && "left-0",
            "flex flex-col gap-0.5 rounded-md border border-ink-100 dark:border-ink-700",
            "bg-bg dark:bg-ink-900 shadow-lg",
            @class
          ]
        }
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc "The command that reveals a popover, for a caller opening one from elsewhere."
  def open_popover(id) do
    # display: "flex" — the panel is a flex column; JS.toggle would otherwise reveal
    # it as display:block and drop the column layout and row gaps.
    %JS{}
    |> JS.toggle(to: "##{id}-panel", display: "flex")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-trigger")
  end

  @doc "The command that dismisses a popover."
  def close_popover(id) do
    %JS{}
    |> JS.hide(to: "##{id}-panel")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-trigger")
  end
end
