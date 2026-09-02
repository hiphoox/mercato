defmodule MercatoWeb.Listings.BrowseLiveNoConditionsTest do
  @moduledoc """
  The browse page on a marketplace that configures no conditions at all — a
  services or digital-goods instance, where every listing's condition is blank.
  """

  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias Mercato.Listings

  setup do
    put_setting(:listing_conditions, [])

    seller = generate(user())
    listing = generate(listing(actor: seller, title: "An hour of tutoring"))
    generate(listing_image(listing: listing))
    Listings.publish_listing!(listing, actor: seller)

    :ok
  end

  test "leaves the condition facet out of the sheet entirely", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#browse-filters-sheet")
    refute has_element?(view, "#browse-sheet-condition")
  end

  test "ignores a condition asked for by hand, since there are none to ask for", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/?condition=new")

    assert render(view) =~ "An hour of tutoring"
    refute has_element?(view, "#browse-chip-condition")
  end
end
