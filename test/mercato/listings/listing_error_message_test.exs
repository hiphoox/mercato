defmodule Mercato.Listings.ListingErrorMessageTest do
  @moduledoc """
  Error messages leave the core layer translatable.

  A message that interpolates its value produces a different string every time,
  and a translator can match none of them. The message must stay a template and
  carry its values alongside, for the web layer to fill in once translated —
  see `docs/architecture/i18n-copy.md`.
  """
  use Mercato.DataCase, async: false

  import Mercato.TestGenerators

  alias Mercato.Listings
  alias MercatoWeb.CoreComponents

  setup do
    seller = generate(user())

    %{seller: seller, listing: generate(listing(actor: seller))}
  end

  defp error_for(%Ash.Error.Invalid{errors: errors}, field) do
    Enum.find(errors, &(&1.field == field))
  end

  describe "an error carrying a value" do
    test "keeps the value out of the message", %{listing: listing} do
      for _ <- 1..Listings.max_images(), do: add_image!(listing)

      {:error, invalid} = add_image(listing)
      error = error_for(invalid, :image)

      assert error.message =~ "%{limit}"
      refute error.message =~ to_string(Listings.max_images())
      assert error.vars[:limit] == Listings.max_images()
    end

    test "reads with the value once the web layer translates it", %{listing: listing} do
      for _ <- 1..Listings.max_images(), do: add_image!(listing)

      {:error, invalid} = add_image(listing)
      error = error_for(invalid, :image)

      rendered = CoreComponents.translate_error({error.message, error.vars})

      assert rendered =~ to_string(Listings.max_images())
      refute rendered =~ "%{limit}"
    end
  end

  defp add_image(listing) do
    Listings.add_listing_image(
      %{listing_id: listing.id, image: png_bytes(), filename: "photo.png"},
      authorize?: false
    )
  end

  defp add_image!(listing) do
    {:ok, image} = add_image(listing)
    image
  end
end
