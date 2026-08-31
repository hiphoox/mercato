defmodule Mercato.Listings.Listing.Preparations.Facets do
  @moduledoc """
  Narrows a read by the facets the marketplace declares.

  A custom preparation because the narrowings are configuration rather than
  source: the action cannot name them one by one and still let a marketplace
  add its own. It reads the declarations, takes the values stated against them,
  and builds one filter per facet in force.

  A value it cannot use is dropped rather than refused — an unknown facet, an
  empty string, a bound that is not a number. A stale or hand-typed address
  should land on the grid, the same forgiveness an unknown category or an
  unrecognised order already gets, and the values a facet accepts are checked
  where they are typed rather than here.
  """

  use Ash.Resource.Preparation

  import Ash.Expr

  alias Mercato.Discovery
  alias Mercato.Discovery.Facet

  @impl true
  def prepare(query, _opts, _context) do
    stated = Ash.Query.get_argument(query, :filters) || %{}

    Enum.reduce(Discovery.facets(), query, &narrow(&2, &1, value(stated, &1)))
  end

  # Both spellings of a key, since a filter arriving over the wire is keyed by
  # string where one built in the app is keyed by atom.
  defp value(stated, %Facet{key: key}) do
    Map.get(stated, key) || Map.get(stated, to_string(key))
  end

  defp narrow(query, _facet, nil), do: query
  defp narrow(query, _facet, ""), do: query

  defp narrow(query, %Facet{kind: :select} = facet, value) do
    Ash.Query.filter(query, ^expr(^reference(facet) == ^value))
  end

  defp narrow(query, %Facet{kind: :range} = facet, bounds) do
    query
    |> bound(facet, bound(bounds, :min), :>=)
    |> bound(facet, bound(bounds, :max), :<=)
  end

  defp bound(query, _facet, nil, _operator), do: query

  defp bound(query, facet, value, :>=) do
    Ash.Query.filter(query, ^expr(^reference(facet) >= ^value))
  end

  defp bound(query, facet, value, :<=) do
    Ash.Query.filter(query, ^expr(^reference(facet) <= ^value))
  end

  defp bound(bounds, end_of_range) when is_map(bounds) do
    case Map.get(bounds, end_of_range) || Map.get(bounds, to_string(end_of_range)) do
      value when is_integer(value) -> value
      _unusable -> nil
    end
  end

  defp bound(_bounds, _end_of_range), do: nil

  defp reference(%Facet{field: {path, name}}), do: ref(path, name)
  defp reference(%Facet{field: name}), do: ref(name)
end
