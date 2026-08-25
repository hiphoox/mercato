defmodule Mercato.Listings.Listing.Calculations.DisplayPrice do
  @moduledoc "A listing's price as a person reads it, in the listing's own currency."
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: [:price, :currency]

  @impl true
  def calculate(listings, _opts, _context) do
    Enum.map(listings, &Mercato.Money.format(&1.price, &1.currency))
  end
end
