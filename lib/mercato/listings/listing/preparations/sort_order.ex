defmodule Mercato.Listings.Listing.Preparations.SortOrder do
  @moduledoc """
  Reads a query in the order it was asked for, from the orders the marketplace
  declares.

  A custom preparation because the orders are configuration rather than source:
  `build/1` takes a static sort, and an action naming the orders one by one
  could not be extended without being edited.

  An order nobody offers is refused rather than ignored, which is where this
  parts company with the facets beside it. A facet is forgiving because a stale
  address should still land on the grid; an order is not a narrowing, so a
  request for one that does not exist is a caller's mistake rather than a
  buyer's stale link. The web layer settles an unreadable order into the
  default before it ever reaches here.
  """

  use Ash.Resource.Preparation

  alias Mercato.Discovery

  @impl true
  def prepare(query, _opts, _context) do
    case asked_for(query) do
      {:ok, sort} -> Ash.Query.sort(query, Discovery.order_by(sort))
      :error -> refuse(query)
    end
  end

  # No order asked for is the marketplace's own default, which is what lets a
  # caller read the plain shelf without naming one.
  defp asked_for(query) do
    case Ash.Query.get_argument(query, :sort) do
      nil -> {:ok, Discovery.default_sort()}
      named -> Discovery.fetch_sort(named)
    end
  end

  defp refuse(query) do
    Ash.Query.add_error(query,
      field: :sort,
      message: "is not an order this marketplace offers"
    )
  end
end
