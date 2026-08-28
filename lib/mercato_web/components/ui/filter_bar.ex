defmodule MercatoWeb.UI.FilterBar do
  @moduledoc """
  The bar a collection is narrowed and ordered from, and the controls on it.

  One row of pills, each naming the value in force rather than the facet —
  a pill reading "Bikes" says more than one reading "Category", and the pill
  only says "Category" while nothing has been picked. Everything that does not
  fit the row moves into a sheet behind a single button, so the bar stays one
  line at every width instead of wrapping into a wall of controls.

  The pills stay black and white in both states, which is what keeps the
  primary color to actions — a filter narrows what is on screen, it does not
  act on anything.

      <.filter_bar id="browse-filters">
        <.filter_menu id="sort" label="Newest">
          <.filter_option label="Newest" selected phx-click="sort" />
        </.filter_menu>

        <:chips><.filter_chip label="Bikes" removable phx-click="clear" /></:chips>
      </.filter_bar>
  """
  use MercatoWeb, :html

  import MercatoWeb.UI.Popover

  @doc """
  Renders the bar.

  It sticks to the top of the column it scrolls in and bleeds to that column's
  edges, so the controls stay reachable however far down the collection the
  reader has gone.
  """
  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true, doc: "the row of controls"
  slot :chips, doc: "the filters already applied; the row is left out when there are none"

  def filter_bar(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "sticky top-0 z-30 -mx-4 px-4 py-3 md:-mx-8 md:px-8",
        "bg-bg dark:bg-ink-900 shadow-sm",
        "border-y border-ink-100 dark:border-ink-700",
        @class
      ]}
      {@rest}
    >
      <div class="flex items-center gap-2">
        {render_slot(@inner_block)}
      </div>

      <div
        :if={@chips != []}
        id={"#{@id}-chips"}
        class="flex flex-wrap items-center gap-2 pt-3"
      >
        {render_slot(@chips)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a pill that opens a panel of choices.

  `label` is what the facet currently says, so the row reads as a sentence about
  the grid below it. `active` inverts the pill once the facet is narrowing that
  grid, which is what distinguishes a filter in force from one merely offered.
  """
  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "the value in force, or the facet while it is unset"
  attr :active, :boolean, default: false, doc: "the facet is narrowing the collection"

  attr :role, :string,
    default: "menu",
    values: ~w(menu dialog),
    doc: "`dialog` when the panel is filled in rather than picked from"

  attr :name, :string,
    default: nil,
    doc: "names the panel when the pill's label is a value rather than the facet"

  attr :class, :any, default: nil, doc: "classes for the panel"
  attr :rest, :global

  slot :inner_block, required: true

  def filter_menu(assigns) do
    ~H"""
    <.popover
      id={@id}
      role={@role}
      align="left"
      label={@name}
      trigger_class={pill_classes(@active)}
      class={@class}
      {@rest}
    >
      <:trigger>
        {@label}
        <.icon name="hero-chevron-down" aria-hidden="true" class="size-4 flex-none opacity-70" />
      </:trigger>
      {render_slot(@inner_block)}
    </.popover>
    """
  end

  @doc """
  Renders a pill that acts rather than opens a panel of its own — the button
  onto the sheet holding every filter that did not fit the row.
  """
  attr :label, :string, required: true
  attr :icon, :string, default: nil, doc: "heroicon name, e.g. \"hero-adjustments-horizontal\""
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled aria-haspopup aria-expanded aria-controls)

  def filter_button(assigns) do
    ~H"""
    <button
      type="button"
      class={
        [
          "flex items-center gap-2",
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100",
          pill_classes(false),
          # Heavier than the pills beside it: it stands for every facet at once,
          # so it reads as the end of the row rather than another item in it.
          "border-[1.5px] border-ink-900 dark:border-white font-bold",
          @class
        ]
      }
      {@rest}
    >
      <.icon :if={@icon} name={@icon} aria-hidden="true" class="size-4 flex-none" />
      {@label}
    </button>
    """
  end

  @doc """
  Renders one choice inside a `filter_menu/1` panel.

  Renders an `<a>` when choosing it goes somewhere — a scope that lives in the
  URL — and a `<button>` otherwise, so one row covers both without the caller
  picking an element.
  """
  attr :label, :string, required: true
  attr :selected, :boolean, default: false
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled phx-click phx-value-sort phx-value-category)

  def filter_option(assigns) do
    assigns = assign(assigns, :classes, option_classes(assigns))

    ~H"""
    <.link
      :if={@patch || @navigate}
      patch={@patch}
      navigate={@navigate}
      role="menuitemradio"
      aria-checked={to_string(@selected)}
      class={@classes}
      {@rest}
    >
      <.filter_option_content label={@label} selected={@selected} />
    </.link>
    <button
      :if={!@patch && !@navigate}
      type="button"
      role="menuitemradio"
      aria-checked={to_string(@selected)}
      class={@classes}
      {@rest}
    >
      <.filter_option_content label={@label} selected={@selected} />
    </button>
    """
  end

  attr :label, :string, required: true
  attr :selected, :boolean, required: true

  defp filter_option_content(assigns) do
    ~H"""
    <span class="truncate">{@label}</span>
    <.icon
      :if={@selected}
      name="hero-check"
      aria-hidden="true"
      class="size-4 flex-none text-primary-500"
    />
    """
  end

  defp option_classes(assigns) do
    [
      "flex items-center justify-between gap-3 w-full min-h-10 px-2.5 rounded-md",
      "text-body-sm text-left no-underline cursor-pointer transition-colors",
      "hover:bg-bg-2 dark:hover:bg-ink-700",
      "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100",
      if(assigns.selected,
        do: "font-bold text-ink-900 dark:text-white",
        else: "font-medium text-ink-700 dark:text-ink-100"
      ),
      assigns.class
    ]
  end

  defp pill_classes(active) do
    [
      "h-10 px-3.5 rounded-full border whitespace-nowrap",
      "text-body-sm font-semibold cursor-pointer transition-colors",
      if(active,
        do:
          "bg-ink-900 border-[1.5px] border-ink-900 text-white " <>
            "dark:bg-white dark:border-white dark:text-ink-900",
        else:
          "bg-bg dark:bg-ink-900 border-ink-300 dark:border-ink-700 " <>
            "text-ink-900 dark:text-white hover:border-ink-900 dark:hover:border-white"
      )
    ]
  end
end
