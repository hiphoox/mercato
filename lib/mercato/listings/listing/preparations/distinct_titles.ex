defmodule Mercato.Listings.Listing.Preparations.DistinctTitles do
  @moduledoc """
  Keeps one listing per title, ignoring case, and caps how many come back.

  A custom preparation because the data layer has no `distinct`: the read
  over-fetches, folds titles that differ only in case together here, and takes
  the first few. Five sellers listing the same thing is one completion, not five.
  """

  use Ash.Resource.Preparation

  @limit 5

  @impl true
  def prepare(query, _opts, _context) do
    Ash.Query.after_action(query, fn _query, listings ->
      {:ok, listings |> Enum.uniq_by(&String.downcase(&1.title)) |> Enum.take(@limit)}
    end)
  end
end
