defmodule MercatoWeb.UI.Pager do
  @moduledoc """
  Numbered pages under a collection too long to draw at once.

  Every page has an address, which is the reason this is numbered rather than a
  button that appends: a page reached by scrolling cannot be linked, shared, or
  returned to with the back button, and the grid above this one keeps all of
  its state in the query string for exactly that reason.

  A long run is elided rather than drawn in full — the first page, the last,
  and the ones either side of the page being read, with a marked gap where
  numbers were left out. Forty pages would otherwise draw forty links, which is
  a worse way to reach page 20 than the two either side of it.

  The page being read is not a link: it is where the reader already is, and it
  carries `aria-current="page"` so a screen reader says so. An end that has
  nowhere to go renders as a disabled control rather than disappearing, so the
  row does not change width on the first and last pages.

  Given a total it also states the range in front of the reader. The two halves
  answer different questions — how much matched, and which of it you are
  looking at — so a collection short enough to need no controls still says how
  much of it there is.

      <.pager page={@page} pages={@pages} path={&~p"/?page=\#{&1}"} />
      <.pager page={@page} pages={@pages} path={...} total={@total} page_size={24} />
  """
  use MercatoWeb, :html

  @doc """
  Renders a pager for a collection spanning more than one page.

  `path` is given the page number and returns where that page lives, so the
  caller keeps whatever else its address carries — a search term, a filter, an
  order — rather than this component knowing about any of it.

  A collection with nothing to count and nowhere to go renders nothing, rather
  than a landmark announcing a single page to reach.
  """
  attr :page, :integer, required: true, doc: "the page being read, from 1"
  attr :pages, :integer, required: true, doc: "how many there are in total"

  attr :path, :any,
    required: true,
    doc: "fun(page_number) -> path, so the caller keeps its facets"

  attr :total, :integer, default: nil, doc: "how much matched; omitted leaves the range unstated"
  attr :page_size, :integer, default: nil, doc: "how much fits a page, to read the range from"
  attr :class, :any, default: nil
  attr :rest, :global

  def pager(assigns) do
    assigns =
      assigns
      |> assign(:slots, slots(assigns.page, assigns.pages))
      |> assign(:ranged?, ranged?(assigns))
      |> assign(:stepped?, assigns.pages > 1)

    ~H"""
    <nav
      :if={@ranged? or @stepped?}
      aria-label={gettext("Pagination")}
      class={["flex flex-wrap items-center justify-between gap-3", @class]}
      {@rest}
    >
      <%!-- Announced, because what changes when a page is stepped is the rows
            above this line rather than anything the reader is looking at. --%>
      <span
        :if={@ranged?}
        data-role="summary"
        aria-live="polite"
        class="text-caption-lg text-ink-500"
      >
        {range(@page, @total, @page_size)}
      </span>

      <%!-- Pushes the controls to the end of the row on their own, so a pager
            with no range to state still centres them. --%>
      <div :if={!@ranged?} class="flex-1"></div>

      <div :if={@stepped?} class="flex items-center gap-1">
        <.step
          role="prev"
          label={gettext("Previous page")}
          icon="hero-chevron-left-micro"
          path={@page > 1 && @path.(@page - 1)}
        />

        <%!-- Not a list: these are peers with no order to announce beyond the
              numbers they already read as. --%>
        <span :for={slot <- @slots} class="contents">
          <.number :if={slot != :gap} number={slot} current?={slot == @page} path={@path} />
          <span
            :if={slot == :gap}
            data-role="gap"
            aria-hidden="true"
            class="px-1 text-body-sm text-ink-300 select-none"
          >
            …
          </span>
        </span>

        <.step
          role="next"
          label={gettext("Next page")}
          icon="hero-chevron-right-micro"
          path={@page < @pages && @path.(@page + 1)}
        />
      </div>

      <div :if={!@ranged?} class="flex-1"></div>
    </nav>
    """
  end

  defp ranged?(%{total: total, page_size: size})
       when is_integer(total) and total > 0 and is_integer(size),
       do: true

  defp ranged?(_assigns), do: false

  # Counted from the reader's position rather than from the result set, since
  # what this answers is which part of it is on the screen.
  defp range(page, total, size) do
    gettext("Showing %{first}–%{last} of %{total}",
      first: (page - 1) * size + 1,
      last: min(page * size, total),
      total: total
    )
  end

  # A run this short is drawn whole: eliding it would replace a number with a
  # gap that costs the same width and offers nothing to click.
  @whole 7

  # Nowhere to step means no numbers to draw, and a range of `1..0` to build
  # them from is not one.
  defp slots(_page, pages) when pages < 2, do: []

  defp slots(_page, pages) when pages <= @whole, do: Enum.to_list(1..pages)

  # Otherwise the first page, the last, and the reader's immediate neighbours.
  # Deduplicated, so a window running into an end names that page once rather
  # than twice.
  defp slots(page, pages) do
    [1, page - 1, page, page + 1, pages]
    |> Enum.filter(&(&1 in 1..pages//1))
    |> Enum.uniq()
    |> Enum.sort()
    |> elide()
  end

  # A gap wherever the numbers kept are not consecutive, so 1 beside 19 reads
  # as a jump rather than as the whole run.
  defp elide([first | rest]) do
    rest
    |> Enum.reduce([first], fn number, [previous | _] = kept ->
      if number - previous > 1, do: [number, :gap | kept], else: [number | kept]
    end)
    |> Enum.reverse()
  end

  attr :number, :integer, required: true
  attr :current?, :boolean, required: true
  attr :path, :any, required: true

  @cell "flex h-9 min-w-9 items-center justify-center rounded-lg px-2 text-body-sm " <>
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"

  defp number(%{current?: true} = assigns) do
    assigns = assign(assigns, :cell, @cell)

    ~H"""
    <span
      data-role="page"
      aria-current="page"
      class={[@cell, "border-[1.5px] border-ink-900 font-bold text-ink-900 dark:text-white"]}
    >
      {@number}
    </span>
    """
  end

  defp number(assigns) do
    assigns = assign(assigns, :cell, @cell)

    ~H"""
    <.link
      patch={@path.(@number)}
      data-role="page"
      aria-label={gettext("Page %{number}", number: @number)}
      class={[@cell, "font-medium text-ink-500 no-underline transition-colors hover:text-ink-900"]}
    >
      {@number}
    </.link>
    """
  end

  # An end with nowhere to go is drawn rather than dropped, so stepping through
  # the pages does not shift the row sideways under the pointer that is
  # clicking it.
  attr :role, :string, required: true
  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :path, :any, required: true, doc: "where the step goes, or false where it goes nowhere"

  defp step(%{path: false} = assigns) do
    assigns = assign(assigns, :cell, @cell)

    ~H"""
    <span
      data-role={@role}
      aria-disabled="true"
      aria-label={@label}
      class={[@cell, "bg-ink-100 text-ink-300"]}
    >
      <.icon name={@icon} aria-hidden="true" class="size-4" />
    </span>
    """
  end

  defp step(assigns) do
    assigns = assign(assigns, :cell, @cell)

    ~H"""
    <.link
      patch={@path}
      data-role={@role}
      aria-label={@label}
      class={[@cell, "text-ink-500 transition-colors hover:bg-ink-100 hover:text-ink-900"]}
    >
      <.icon name={@icon} aria-hidden="true" class="size-4" />
    </.link>
    """
  end
end
