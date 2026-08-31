defmodule Mercato.Discovery do
  @moduledoc """
  How a buyer finds a listing: the ways the browse grid can be narrowed.

  The facets are configuration rather than code, so a marketplace offers what
  its own catalog has. The default is what a general marketplace needs and no
  more — the category a listing is filed under, what it costs, and the
  condition it is in — and a marketplace selling something else replaces the
  list rather than editing the grid.

  The orders the grid can be read in are configuration for the same reason,
  and declared apart from the facets: an order states how the shelf is read
  where a facet states what is on it, which is why clearing the filters leaves
  the order standing.

  Free text is deliberately not a facet. A term is matched and ranked, which is
  the search engine's job rather than the operator's; a facet is a narrowing
  the operator chose to offer. Keeping the two apart is what lets the engine be
  swapped without changing which filters a buyer sees.
  """

  alias Mercato.Discovery.Facet
  alias Mercato.Discovery.Sort

  @default_facets [
    [
      key: :category,
      kind: :select,
      field: {[:category], :slug},
      label: "Category",
      options: {Mercato.Listings, :category_options, []}
    ],
    [
      key: :price,
      kind: :range,
      field: :price,
      label: "Price",
      parse: {Mercato.Money, :to_minor, []},
      format: {Mercato.Money, :amount, []}
    ],
    [
      key: :condition,
      kind: :select,
      field: :condition,
      label: "Condition",
      placement: :sheet,
      options: {Mercato.Listings, :condition_options, []}
    ]
  ]

  @doc """
  Every facet this marketplace narrows the browse grid by, in the order they
  are offered.

  A marketplace configuring none is browsing an unnarrowed grid, which is what
  an instance selling one kind of thing wants.
  """
  @spec facets() :: [Facet.t()]
  def facets do
    :mercato
    |> Application.get_env(:browse_facets, @default_facets)
    |> Enum.map(&Facet.new/1)
  end

  @default_sorts [
    [key: :newest, label: "Newest", by: [published_at: :desc, inserted_at: :desc]],
    [key: :price_asc, label: "Price: low to high", by: [price: :asc]],
    [key: :price_desc, label: "Price: high to low", by: [price: :desc]]
  ]

  @doc """
  Every order this marketplace offers the browse grid in, in the order they are
  offered.

  The default is recency and the buyer's own price signal, which is all a front
  door can honestly order by before it has a ranking to sort on.
  """
  @spec sorts() :: [Sort.t()]
  def sorts do
    :mercato
    |> Application.get_env(:browse_sorts, @default_sorts)
    |> Enum.map(&Sort.new/1)
  end

  @doc """
  The order the grid is read in when none is asked for.

  The first one declared, so a marketplace states its default by putting it
  first rather than by naming it twice.
  """
  @spec default_sort() :: Sort.t()
  def default_sort, do: hd(sorts())

  @doc """
  The order a key names, where this marketplace offers one.

  Reads a key stated as a string as readily as one stated as an atom, since an
  address states it as text — and without minting an atom for text that names
  no order, which is what keeps a hand-typed address from filling the atom
  table.
  """
  @spec fetch_sort(atom() | String.t()) :: {:ok, Sort.t()} | :error
  def fetch_sort(key) do
    named = to_string(key)

    case Enum.find(sorts(), &(to_string(&1.key) == named)) do
      nil -> :error
      sort -> {:ok, sort}
    end
  end

  @doc """
  The columns a read is sorted by to honour an order.

  An order's own columns, then the default order's. Two rows tying on price
  would otherwise come back in whatever order the data layer happened to
  produce, and a grid that reshuffles between two identical reads reads as a
  bug rather than as a tie. Supplied here rather than declared, because a
  marketplace adding an order cannot forget what it never had to write.
  """
  @spec order_by(Sort.t()) :: keyword()
  def order_by(%Sort{} = sort) do
    settle = default_sort()

    if sort.key == settle.key, do: sort.by, else: sort.by ++ settle.by
  end

  @doc "The facet a key names, where this marketplace offers one."
  @spec fetch(atom()) :: {:ok, Facet.t()} | :error
  def fetch(key) do
    case Enum.find(facets(), &(&1.key == key)) do
      nil -> :error
      facet -> {:ok, facet}
    end
  end

  @doc """
  The values a facet offers, already worded.

  Every kind of option list arrives in the same shape, so a category read from
  the catalog and a condition read from configuration draw the same control.
  A facet with no list to offer — a range, whose ends are typed rather than
  picked — offers nothing.
  """
  @spec options(Facet.t()) :: [{String.t(), String.t()}]
  def options(%Facet{options: {module, function, args}}), do: apply(module, function, args)
  def options(%Facet{}), do: []

  @doc """
  The facets an address states, read into the shape the grid narrows by.

  Everything unusable is left out rather than refused: a parameter no facet
  claims, a value stated as empty, a bound that is not a number, and a value a
  facet does not actually offer. A stale or hand-typed address lands on the
  grid, which is the same forgiveness an unrecognised order gets.

  A value chosen from a list is checked against that list, so an address naming
  a category the catalog dropped — or a condition an instance no longer
  configures — browses everything rather than nothing.

  The lists are taken as given where the caller already has them, since a page
  reads them once and then reads many addresses against them.
  """
  @spec from_params(map(), map() | nil) :: map()
  def from_params(params, offered \\ nil) do
    facets = facets()
    offered = offered || Map.new(facets, &{&1.key, options(&1)})

    Enum.reduce(facets, %{}, fn facet, filters ->
      case stated(facet, params, Map.get(offered, facet.key, [])) do
        nil -> filters
        value -> Map.put(filters, facet.key, value)
      end
    end)
  end

  defp stated(%Facet{kind: :range} = facet, params, _offered) do
    [min_param, max_param] = Facet.params(facet)

    case {read(facet, params[min_param]), read(facet, params[max_param])} do
      {nil, nil} -> nil
      {min, max} -> %{min: min, max: max}
    end
  end

  defp stated(%Facet{} = facet, params, offered) do
    [param] = Facet.params(facet)

    case read(facet, params[param]) do
      nil -> nil
      value -> if offers?(offered, value), do: value, else: nil
    end
  end

  defp offers?(offered, value),
    do: Enum.any?(offered, fn {stated, _wording} -> stated == value end)

  defp read(facet, typed) do
    case typed |> to_string() |> String.trim() do
      "" -> nil
      trimmed -> parse(facet, trimmed)
    end
  end

  defp parse(%Facet{parse: {module, function, args}}, typed) do
    case apply(module, function, [typed | args]) do
      {:ok, value} -> value
      _unreadable -> nil
    end
  end

  defp parse(%Facet{kind: :range}, typed) do
    case Integer.parse(typed) do
      {value, ""} -> value
      _unreadable -> nil
    end
  end

  defp parse(%Facet{}, typed), do: typed

  @doc """
  The facets in force, written back as an address states them.

  In the order the facets are declared, so the same narrowing has one address
  however it was arrived at, and a facet that is not narrowing anything leaves
  no empty parameter behind.
  """
  @spec to_params(map()) :: keyword()
  def to_params(filters) do
    Enum.flat_map(facets(), &stated_as(&1, Map.get(filters, &1.key)))
  end

  defp stated_as(%Facet{kind: :range} = facet, bounds) when is_map(bounds) do
    [min_param, max_param] = Facet.param_keys(facet)

    Enum.reject(
      [
        {min_param, write(facet, bounds[:min])},
        {max_param, write(facet, bounds[:max])}
      ],
      fn {_param, value} -> value in [nil, ""] end
    )
  end

  defp stated_as(%Facet{kind: :select} = facet, value) when value not in [nil, ""] do
    [{facet.key, write(facet, value)}]
  end

  defp stated_as(%Facet{}, _unstated), do: []

  defp write(_facet, nil), do: nil

  defp write(%Facet{format: {module, function, args}}, value),
    do: apply(module, function, [value | args])

  defp write(%Facet{}, value), do: to_string(value)

  @doc """
  Whether a facet is narrowing the grid.

  A range counts once either end is stated, since a buyer who named only a
  floor has narrowed the grid as surely as one who named both.
  """
  @spec in_force?(Facet.t(), map()) :: boolean()
  def in_force?(%Facet{kind: :range} = facet, filters) do
    case Map.get(filters, facet.key) do
      %{} = bounds -> not is_nil(bounds[:min]) or not is_nil(bounds[:max])
      _unstated -> false
    end
  end

  def in_force?(%Facet{} = facet, filters) do
    Map.get(filters, facet.key) not in [nil, ""]
  end
end
