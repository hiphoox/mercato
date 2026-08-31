defmodule MercatoWeb.UI.FacetControls do
  @moduledoc """
  The controls a declared facet is stated through, and the words around them.

  A facet says what it narrows and how; this draws the pill, the sheet section
  and the chip that follow from it. One declaration therefore reaches the grid
  and the bar together, and a marketplace adding a facet its catalog needs
  writes no markup at all.

  Two kinds are drawn. One value chosen from a list is a panel of options, with
  the pill reading the value in force rather than the facet, so the bar reads as
  a sentence about the grid below it. A range is typed rather than picked, so it
  is a small form submitted on its own: half a range is a bound the buyer has
  not finished writing, and applying it would empty the grid mid-word.

  The bar and the sheet draw the same facet differently, because they hold
  different numbers of them. The bar shows one facet at a time in a panel over
  the grid, so its values are a list to pick down. The sheet stacks every facet
  at once, so each is one row instead: a marketplace declaring ten facets would
  otherwise scroll past nine lists to reach the tenth.

  A select facet with nothing to offer is left out entirely. An instance
  selling services configures no conditions, and a facet with an empty panel
  reads as a page that failed to load rather than as a facet that does not
  apply.

  The wording is split the way the copy boundary splits it. A facet this
  codebase ships is worded here, as a clause per key returning a literal, so a
  translator can find it. A facet a marketplace declared for itself is worded
  by the operator, and is rendered as configured — see
  `docs/architecture/i18n-copy.md`.
  """
  use MercatoWeb, :html

  import MercatoWeb.UI.FilterBar

  alias Mercato.Discovery
  alias Mercato.Discovery.Facet
  alias Mercato.Listings
  alias Mercato.Money

  @doc """
  Renders the pill a facet is stated from on the bar.
  """
  attr :facet, :map, required: true
  attr :filters, :map, required: true
  attr :options, :map, required: true, doc: "the values each facet offers, keyed by facet"
  attr :path, :any, required: true, doc: "fun(filters) -> the address those facets make"
  attr :prefix, :string, default: "browse"

  def facet_menu(%{facet: %Facet{kind: :select}} = assigns) do
    assigns = assign(assigns, :choices, assigns.options[assigns.facet.key] || [])

    ~H"""
    <.filter_menu
      :if={@choices != []}
      id={"#{@prefix}-#{@facet.key}"}
      label={stated_label(@facet, @filters, @choices)}
      name={label(@facet)}
      active={Discovery.in_force?(@facet, @filters)}
      class="w-64 max-h-72 overflow-y-auto"
    >
      <.facet_options
        facet={@facet}
        filters={@filters}
        choices={@choices}
        path={@path}
        prefix={@prefix}
      />
    </.filter_menu>
    """
  end

  def facet_menu(%{facet: %Facet{kind: :range}} = assigns) do
    ~H"""
    <.filter_menu
      id={"#{@prefix}-#{@facet.key}"}
      label={label(@facet)}
      name={range_label(@facet)}
      role="dialog"
      class="w-72 gap-3 p-3.5"
    >
      <.facet_range facet={@facet} filters={@filters} prefix={"#{@prefix}-#{@facet.key}"} />
    </.filter_menu>
    """
  end

  @doc """
  Renders the section a facet is stated from inside the sheet.

  The sheet holds every facet, including the ones the bar had no room for, so
  the same narrowing is reachable at every width.
  """
  attr :facet, :map, required: true
  attr :filters, :map, required: true
  attr :options, :map, required: true
  attr :path, :any, required: true
  attr :prefix, :string, default: "browse-sheet"

  def facet_section(%{facet: %Facet{kind: :select}} = assigns) do
    [param] = Facet.params(assigns.facet)
    choices = assigns.options[assigns.facet.key] || []

    assigns =
      assigns
      |> assign(:param, param)
      |> assign(:choices, Enum.map(choices, fn {value, wording} -> {wording, value} end))
      |> assign(:chosen, assigns.filters[assigns.facet.key])

    ~H"""
    <section :if={@choices != []} class="flex flex-col gap-3">
      <.facet_heading>{label(@facet)}</.facet_heading>
      <%!-- One row rather than a list of every value. The sheet stacks every
            facet the marketplace declares, so a facet that grows with its
            option list grows the sheet with it, and a marketplace offering ten
            of them would be scrolling past nine to reach the tenth. --%>
      <.form
        for={%{}}
        id={"#{@prefix}-#{@facet.key}-form"}
        phx-change="apply_facet"
        class="contents"
      >
        <input type="hidden" name="facet" value={@facet.key} />
        <.input
          type="select"
          id={"#{@prefix}-#{@facet.key}"}
          name={@param}
          value={@chosen}
          prompt={any_label(@facet)}
          options={@choices}
        />
      </.form>
    </section>
    """
  end

  def facet_section(%{facet: %Facet{kind: :range}} = assigns) do
    ~H"""
    <section class="flex flex-col gap-3">
      <.facet_heading>{label(@facet)}</.facet_heading>
      <.facet_range facet={@facet} filters={@filters} prefix={"#{@prefix}-#{@facet.key}"} />
    </section>
    """
  end

  @doc """
  Renders the chip naming a facet in force, which removes it when clicked.

  Drawn only while the facet is narrowing the grid, so the row states what is
  in force rather than what is on offer.
  """
  attr :facet, :map, required: true
  attr :filters, :map, required: true
  attr :options, :map, required: true
  attr :prefix, :string, default: "browse"

  def facet_chip(assigns) do
    ~H"""
    <.filter_chip
      :if={Discovery.in_force?(@facet, @filters)}
      id={"#{@prefix}-chip-#{@facet.key}"}
      label={chip_label(@facet, @filters, @options[@facet.key] || [])}
      removable
      phx-click="drop_facet"
      phx-value-facet={@facet.key}
    />
    """
  end

  # Only the bar draws its choices as a list: it shows one facet at a time,
  # inside a panel that opens over the grid rather than stacking with the rest.
  attr :facet, :map, required: true
  attr :filters, :map, required: true
  attr :choices, :list, required: true
  attr :path, :any, required: true
  attr :prefix, :string, required: true

  defp facet_options(assigns) do
    ~H"""
    <.filter_option
      id={"#{@prefix}-#{@facet.key}-any"}
      label={any_label(@facet)}
      selected={not Discovery.in_force?(@facet, @filters)}
      patch={@path.(Map.put(@filters, @facet.key, nil))}
    />
    <%!-- Worded by whoever owns the list: a category is named by the operator
          and a condition by the marketplace's configuration, so both are data
          rather than copy to translate. --%>
    <.filter_option
      :for={{value, wording} <- @choices}
      id={"#{@prefix}-#{@facet.key}-#{value}"}
      label={wording}
      selected={value == @filters[@facet.key]}
      patch={@path.(Map.put(@filters, @facet.key, value))}
    />
    """
  end

  attr :facet, :map, required: true
  attr :filters, :map, required: true
  attr :prefix, :string, required: true

  defp facet_range(assigns) do
    [min_param, max_param] = Facet.params(assigns.facet)
    bounds = assigns.filters[assigns.facet.key] || %{}

    assigns =
      assigns
      |> assign(:min_param, min_param)
      |> assign(:max_param, max_param)
      |> assign(:min, written(assigns.facet, bounds[:min]))
      |> assign(:max, written(assigns.facet, bounds[:max]))

    ~H"""
    <.form for={%{}} id={"#{@prefix}-form"} phx-submit="apply_facet" class="flex flex-col gap-2.5">
      <input type="hidden" name="facet" value={@facet.key} />
      <div class="flex items-end gap-2.5">
        <.input
          type="number"
          id={"#{@prefix}-min"}
          name={@min_param}
          value={@min}
          label={gettext("Min")}
          min="0"
          step="0.01"
        />
        <.input
          type="number"
          id={"#{@prefix}-max"}
          name={@max_param}
          value={@max}
          label={gettext("Max")}
          min="0"
          step="0.01"
        />
      </div>
      <.button type="submit" size="sm">{gettext("Apply")}</.button>
    </.form>
    """
  end

  slot :inner_block, required: true

  defp facet_heading(assigns) do
    ~H"""
    <h3 class="text-caption-lg font-bold uppercase tracking-wide text-ink-500">
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc """
  Every value each facet offers, read once so a control never reads the catalog
  while it draws.
  """
  @spec options([Facet.t()]) :: map()
  def options(facets) do
    Map.new(facets, &{&1.key, Discovery.options(&1)})
  end

  @doc """
  What a facet is called.

  A clause per facet this codebase ships, so extraction can see the words; a
  marketplace's own facet is called what the marketplace called it.
  """
  @spec label(Facet.t()) :: String.t()
  def label(%Facet{key: :category}), do: gettext("Category")
  def label(%Facet{key: :price}), do: gettext("Price")
  def label(%Facet{key: :condition}), do: gettext("Condition")
  def label(%Facet{label: declared}), do: declared

  # The pill states the value in force where there is one, since a pill reading
  # "Bikes" says more about the grid than one reading "Category".
  defp stated_label(facet, filters, choices) do
    case Enum.find(choices, fn {value, _wording} -> value == filters[facet.key] end) do
      {_value, wording} -> wording
      nil -> label(facet)
    end
  end

  defp any_label(%Facet{key: :category}), do: gettext("All categories")
  defp any_label(%Facet{key: :condition}), do: gettext("Any condition")
  defp any_label(%Facet{}), do: gettext("Any")

  defp range_label(%Facet{key: :price}), do: gettext("Price range")
  defp range_label(%Facet{} = facet), do: label(facet)

  defp chip_label(%Facet{kind: :range} = facet, filters, _choices) do
    bounds = filters[facet.key] || %{}

    range_chip(facet, bounds[:min], bounds[:max])
  end

  defp chip_label(facet, filters, choices) do
    stated_label(facet, filters, choices)
  end

  # Three whole messages rather than one built from a fragment and a bound:
  # which end is open changes the sentence, not just a word inside it.
  defp range_chip(%Facet{key: :price}, min, nil), do: gettext("From %{min}", min: money(min))
  defp range_chip(%Facet{key: :price}, nil, max), do: gettext("Up to %{max}", max: money(max))

  defp range_chip(%Facet{key: :price}, min, max),
    do: gettext("%{min} – %{max}", min: money(min), max: money(max))

  defp range_chip(facet, min, nil),
    do: gettext("From %{min}", min: written(facet, min))

  defp range_chip(facet, nil, max),
    do: gettext("Up to %{max}", max: written(facet, max))

  defp range_chip(facet, min, max),
    do: gettext("%{min} – %{max}", min: written(facet, min), max: written(facet, max))

  defp money(amount), do: Money.format(amount, Listings.currency())

  defp written(_facet, nil), do: nil

  defp written(%Facet{format: {module, function, args}}, value),
    do: apply(module, function, [value | args])

  defp written(%Facet{}, value), do: to_string(value)
end
