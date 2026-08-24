defmodule Mercato.Listings.ListingConditionTest do
  @moduledoc """
  The condition list is per-instance configuration, so these tests rewrite
  application env and cannot run async.
  """
  use Mercato.DataCase, async: false

  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    original = Application.get_env(:mercato, :listing_conditions)

    on_exit(fn ->
      case original do
        nil -> Application.delete_env(:mercato, :listing_conditions)
        list -> Application.put_env(:mercato, :listing_conditions, list)
      end
    end)

    %{seller: generate(user())}
  end

  test "follows a replaced condition list without a recompile", %{seller: seller} do
    Application.put_env(:mercato, :listing_conditions, ["roadworthy", "project_car"])

    assert {:ok, listing} =
             Listings.create_listing(
               %{title: "1974 coupe", price: 850_000, condition: "project_car"},
               actor: seller,
               authorize?: false
             )

    assert listing.condition == "project_car"

    assert {:error, %Ash.Error.Invalid{}} =
             Listings.create_listing(
               %{title: "1974 coupe", price: 850_000, condition: "like_new"},
               actor: seller,
               authorize?: false
             )
  end

  test "refuses every condition when the marketplace configures none", %{seller: seller} do
    Application.put_env(:mercato, :listing_conditions, [])

    assert {:error, %Ash.Error.Invalid{}} =
             Listings.create_listing(%{title: "Consulting hour", price: 12_000, condition: "new"},
               actor: seller,
               authorize?: false
             )

    assert {:ok, listing} =
             Listings.create_listing(%{title: "Consulting hour", price: 12_000},
               actor: seller,
               authorize?: false
             )

    assert listing.condition == nil
  end
end
