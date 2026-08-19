defmodule MercatoWeb.UI.Breadcrumb do
  @moduledoc """
  Hierarchical trail showing where the current page sits.

  The final crumb is always the current page: it is never a link, and carries
  `aria-current="page"`. Earlier crumbs link when given a `:navigate` target and
  render as plain text when not, so a trail can include a grouping level that
  has no page of its own.

      <.breadcrumb items={[
        %{label: "Home", navigate: ~p"/"},
        %{label: "Account"}
      ]} />
  """
  use MercatoWeb, :html

  @doc """
  Renders a breadcrumb trail.

  Each item is a map with a `:label` and an optional `:navigate` path. An empty
  list renders nothing, rather than an empty landmark for screen readers to
  announce.
  """
  attr :items, :list, required: true, doc: "crumbs, outermost first; the last is current"
  attr :class, :any, default: nil
  attr :rest, :global

  def breadcrumb(%{items: []} = assigns), do: ~H""

  def breadcrumb(assigns) do
    assigns = assign(assigns, :last_index, length(assigns.items) - 1)

    ~H"""
    <nav
      aria-label="Breadcrumb"
      class={["text-body-sm text-ink-500", @class]}
      {@rest}
    >
      <ol class="flex flex-wrap items-center gap-2">
        <li :for={{item, index} <- Enum.with_index(@items)} class="flex items-center gap-2">
          <.crumb item={item} current?={index == @last_index} />
          <.icon
            :if={index != @last_index}
            name="hero-chevron-right-micro"
            data-role="separator"
            aria-hidden="true"
            class="size-3.5 text-ink-300"
          />
        </li>
      </ol>
    </nav>
    """
  end

  attr :item, :map, required: true
  attr :current?, :boolean, required: true

  defp crumb(%{current?: true} = assigns) do
    ~H"""
    <span aria-current="page" class="font-semibold text-ink-900 dark:text-white">
      {@item.label}
    </span>
    """
  end

  defp crumb(assigns) do
    ~H"""
    <.link
      :if={@item[:navigate]}
      navigate={@item.navigate}
      class="font-medium text-ink-500 no-underline hover:text-ink-900 transition-colors"
    >
      {@item.label}
    </.link>
    <span :if={!@item[:navigate]} class="font-medium text-ink-500">{@item.label}</span>
    """
  end
end
