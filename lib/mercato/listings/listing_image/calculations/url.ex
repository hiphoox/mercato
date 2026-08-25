defmodule Mercato.Listings.ListingImage.Calculations.Url do
  @moduledoc "Where an image in a listing's gallery can be fetched from."
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: [:storage_key]

  @impl true
  def calculate(images, _opts, _context) do
    Enum.map(images, &storage().url(&1.storage_key))
  end

  defp storage, do: Application.fetch_env!(:mercato, :storage_adapter)
end
