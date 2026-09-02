defmodule MercatoWeb.Listings.ListingDetailNoPhotosTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    # A marketplace setting no minimum is what makes a photoless listing legal,
    # so the placeholder is a statement rather than a fault.
    put_setting(:listing_min_images, 0)

    :ok
  end

  test "explains an empty gallery rather than showing a broken box", %{conn: conn} do
    seller = generate(user())
    bare = Listings.publish_listing!(generate(listing(actor: seller)), actor: seller)

    {:ok, view, _html} = live(conn, ~p"/listings/#{bare}")

    assert has_element?(view, "#listing-detail")
    assert has_element?(view, "#gallery-no-photos")
    refute has_element?(view, "#gallery-hero")
    refute has_element?(view, "#gallery-thumbs")
  end
end
