defmodule Mercato.Listings.ListingConditionTest do
  @moduledoc """
  The condition list is a platform setting, so these tests write the settings
  row their own sandbox holds.
  """
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    %{seller: generate(user()), category: generate(category())}
  end

  test "follows a replaced condition list without a recompile", %{
    seller: seller,
    category: category
  } do
    put_setting(:listing_conditions, ["roadworthy", "project_car"])

    assert {:ok, listing} =
             Listings.create_listing(
               %{
                 title: "1974 coupe",
                 price: 850_000,
                 condition: "project_car",
                 category_id: category.id
               },
               actor: seller,
               authorize?: false
             )

    assert listing.condition == "project_car"

    assert {:error, %Ash.Error.Invalid{}} =
             Listings.create_listing(
               %{
                 title: "1974 coupe",
                 price: 850_000,
                 condition: "like_new",
                 category_id: category.id
               },
               actor: seller,
               authorize?: false
             )
  end

  test "refuses every condition when the marketplace configures none", %{
    seller: seller,
    category: category
  } do
    put_setting(:listing_conditions, [])

    assert {:error, %Ash.Error.Invalid{}} =
             Listings.create_listing(
               %{
                 title: "Consulting hour",
                 price: 12_000,
                 condition: "new",
                 category_id: category.id
               },
               actor: seller,
               authorize?: false
             )

    assert {:ok, listing} =
             Listings.create_listing(
               %{title: "Consulting hour", price: 12_000, category_id: category.id},
               actor: seller,
               authorize?: false
             )

    assert listing.condition == nil
  end
end
