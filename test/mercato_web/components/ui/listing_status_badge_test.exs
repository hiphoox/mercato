defmodule MercatoWeb.UI.ListingStatusBadgeTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Mercato.Listings.Listing.Status
  alias MercatoWeb.UI.ListingStatusBadge

  defp badge_for(status) do
    render_component(&ListingStatusBadge.listing_status_badge/1, %{status: status})
  end

  describe "wording" do
    test "uses the trader's words rather than the schema's" do
      assert badge_for(:active) =~ "Active"
      assert badge_for(:unavailable) =~ "Paused"
    end

    test "has wording for every state a listing can hold" do
      for status <- Status.values() do
        assert ListingStatusBadge.label(status) != ""
      end
    end
  end

  describe "kind" do
    test "carries a live listing as a healthy state" do
      assert badge_for(:active) =~ "bg-success-bg"
    end

    test "carries a paused listing as a limiting state, not a stopping one" do
      assert badge_for(:unavailable) =~ "bg-warning-bg"
    end

    test "carries a sold listing as one that has come to rest" do
      assert badge_for(:sold) =~ "bg-info-bg"
    end

    test "carries a draft as having no state of its own" do
      assert badge_for(:draft) =~ "bg-ink-100"
    end
  end

  describe "label/1" do
    test "gives the wording without the badge around it" do
      assert ListingStatusBadge.label(:unavailable) == "Paused"
    end
  end
end
