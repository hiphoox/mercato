defmodule MercatoWeb.UI.Menu do
  @moduledoc """
  Menu building blocks: a popup `menu/1` and the `menu_item/1` row.

  Both live here because they are one concept — a row is what a menu is made
  of — but `menu_item/1` is deliberately usable on its own. The sidebar renders
  rows without a popup around them, so a nav link and a dropdown entry share one
  set of states (active, destructive, collapsed) instead of drifting apart.

      <.menu_item icon="hero-user" label="Profile" navigate={~p"/profile"} active />

      <.menu id="user-menu">
        <:trigger><.avatar name="Jane Doe" /></:trigger>
        <.menu_item icon="hero-user" label="Profile" navigate={~p"/profile"} role="menuitem" />
      </.menu>
  """
  use MercatoWeb, :html

  @doc """
  Renders a single menu row.

  Renders an `<a>` when given `:navigate` or `:href`, and a `<button>`
  otherwise, so the same component covers navigation and actions without the
  caller choosing an element.
  """
  attr :label, :string,
    required: true,
    doc: "visible text, and the accessible name when collapsed"

  attr :icon, :string, default: nil, doc: "heroicon name, e.g. \"hero-user\""
  attr :active, :boolean, default: false, doc: "marks the row as the current page"

  attr :collapsed, :any,
    default: false,
    values: [true, false, :responsive],
    doc: """
    Icon-only rail. `true` collapses always; `:responsive` collapses only while the
    sidebar is collapsed (driven by CSS, so no re-render is needed). The label is
    never dropped — it becomes screen-reader-only and a tooltip.
    """

  attr :variant, :atom, default: :default, values: [:default, :danger]
  attr :navigate, :string, default: nil
  attr :href, :string, default: nil
  attr :role, :string, default: nil, doc: "set to \"menuitem\" when inside a popup menu"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(method download target phx-click phx-value-id title)

  def menu_item(assigns) do
    assigns = assign(assigns, :classes, item_classes(assigns))

    ~H"""
    <.link
      :if={@navigate || @href}
      navigate={@navigate}
      href={@href}
      role={@role}
      class={@classes}
      aria-current={@active && "page"}
      title={@collapsed != false && @label}
      {@rest}
    >
      <.menu_item_content icon={@icon} label={@label} collapsed={@collapsed} />
    </.link>
    <button
      :if={!@navigate && !@href}
      type="button"
      role={@role}
      class={@classes}
      aria-current={@active && "page"}
      title={@collapsed != false && @label}
      {@rest}
    >
      <.menu_item_content icon={@icon} label={@label} collapsed={@collapsed} />
    </button>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :collapsed, :any, required: true

  defp menu_item_content(assigns) do
    ~H"""
    <.icon :if={@icon} name={@icon} aria-hidden="true" class="size-5 flex-none" />
    <span class={label_classes(@collapsed)}>{@label}</span>
    """
  end

  defp label_classes(true), do: "sr-only"
  defp label_classes(:responsive), do: "truncate sidebar-collapsed:sr-only"
  defp label_classes(false), do: "truncate"

  defp item_classes(assigns) do
    [
      "flex items-center gap-3 w-full h-11 rounded-md no-underline",
      "text-body-md font-medium text-left transition-colors",
      "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100",
      padding_classes(assigns.collapsed),
      variant_classes(assigns.variant, assigns.active),
      assigns.class
    ]
  end

  defp padding_classes(true), do: "justify-center px-0"

  defp padding_classes(:responsive),
    do: "px-3.5 sidebar-collapsed:justify-center sidebar-collapsed:px-0"

  defp padding_classes(false), do: "px-3.5"

  defp variant_classes(:danger, _active),
    do: "text-error-text hover:bg-error-bg"

  defp variant_classes(:default, true),
    do: "bg-primary-050 text-primary-700 font-semibold hover:bg-primary-100"

  defp variant_classes(:default, false),
    do: "text-ink-700 hover:bg-bg-2 hover:text-ink-900 dark:text-ink-100"

  @doc """
  Renders a popup menu anchored to a trigger.

  Open/closed state is held entirely on the client, so no LiveView needs to
  track it. The panel closes on outside click and on Escape.
  """
  attr :id, :string, required: true, doc: "unique id; the trigger and panel derive theirs from it"
  attr :class, :any, default: nil, doc: "classes for the panel"
  attr :rest, :global

  slot :trigger, required: true, doc: "the button's contents"
  slot :inner_block, required: true, doc: "the panel's contents — usually menu_item/1 rows"

  def menu(assigns) do
    ~H"""
    <%!-- click-away lives on the wrapper, not the panel: the trigger sits outside
          the panel, so a panel-scoped handler would fire on the very click that
          opens it and close it again in the same event. --%>
    <div class="relative" phx-click-away={close_menu(@id)} {@rest}>
      <button
        type="button"
        id={"#{@id}-trigger"}
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={open_menu(@id)}
        class={[
          "flex items-center gap-2 rounded-md bg-bg dark:bg-ink-700 shadow-sm cursor-pointer",
          "transition-[filter] hover:brightness-97",
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
        ]}
      >
        {render_slot(@trigger)}
      </button>

      <div
        id={"#{@id}-panel"}
        role="menu"
        aria-labelledby={"#{@id}-trigger"}
        phx-window-keydown={close_menu(@id)}
        phx-key="escape"
        class={
          [
            # The `hidden` class, never the `hidden` attribute: Tailwind's preflight marks
            # [hidden] as `display:none !important`, which beats the inline display that
            # JS.toggle sets and would leave the panel permanently invisible.
            "hidden",
            "absolute right-0 top-[calc(100%+8px)] z-60 w-62 p-2",
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

  defp open_menu(id) do
    # display: "flex" — the panel is a flex column; JS.toggle would otherwise reveal
    # it as display:block and drop the column layout and row gaps.
    %JS{}
    |> JS.toggle(to: "##{id}-panel", display: "flex")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-trigger")
  end

  defp close_menu(id) do
    %JS{}
    |> JS.hide(to: "##{id}-panel")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-trigger")
  end
end
