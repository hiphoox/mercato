defmodule Mercato.Listings.Listing.Condition do
  @moduledoc """
  The wear state of what a listing sells, drawn from the list the marketplace
  has configured.

  Deliberately not an `Ash.Type.Enum`: those fix their values at compile time,
  and this list is per-instance configuration — a services marketplace empties
  it, a vehicle marketplace replaces it. See `Mercato.Listings.conditions/0`.
  """

  use Ash.Type

  @impl true
  def storage_type(_constraints), do: :string

  @impl true
  def cast_input(nil, _constraints), do: {:ok, nil}

  def cast_input(value, _constraints) do
    case Ash.Type.cast_input(:string, value, []) do
      {:ok, nil} -> {:ok, nil}
      {:ok, string} -> cast_configured(string)
      other -> other
    end
  end

  @impl true
  def cast_stored(nil, _constraints), do: {:ok, nil}

  # Not re-checked against the configured list: a row written under an older
  # list must still read back, or reconfiguring would make existing listings
  # unloadable.
  def cast_stored(value, _constraints), do: Ash.Type.cast_stored(:string, value, [])

  @impl true
  def dump_to_native(nil, _constraints), do: {:ok, nil}
  def dump_to_native(value, _constraints), do: Ash.Type.dump_to_native(:string, value, [])

  @impl true
  def generator(_constraints) do
    case Mercato.Listings.conditions() do
      [] -> StreamData.constant(nil)
      conditions -> StreamData.member_of([nil | conditions])
    end
  end

  # Read per cast rather than baked into the type, so config/runtime.exs can
  # change the list without a recompile.
  defp cast_configured(string) do
    if string in Mercato.Listings.conditions() do
      {:ok, string}
    else
      {:error, message: "is not a condition this marketplace uses"}
    end
  end
end
