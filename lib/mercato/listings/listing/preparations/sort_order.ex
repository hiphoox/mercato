defmodule Mercato.Listings.Listing.Preparations.SortOrder do
  @moduledoc """
  Orders a read by the `sort` argument it was given.

  A custom preparation because `build/1` takes a static sort and the order is
  chosen per read. Every order ends in recency: two listings at the same price
  would otherwise come back in whatever order the data layer happened to
  produce, and a grid that reshuffles between two identical reads reads as a
  bug rather than as a tie.
  """

  use Ash.Resource.Preparation

  @impl true
  def prepare(query, _opts, _context) do
    Ash.Query.sort(query, order(Ash.Query.get_argument(query, :sort)))
  end

  defp order(:price_asc), do: [price: :asc, published_at: :desc, inserted_at: :desc]
  defp order(:price_desc), do: [price: :desc, published_at: :desc, inserted_at: :desc]
  defp order(_newest), do: [published_at: :desc, inserted_at: :desc]
end
