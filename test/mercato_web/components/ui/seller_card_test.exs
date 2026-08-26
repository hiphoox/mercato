defmodule MercatoWeb.UI.SellerCardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.SellerCard

  defp slot(name, content) do
    [%{__slot__: name, inner_block: fn _, _ -> content end}]
  end

  defp render_card(assigns) do
    render_component(&SellerCard.seller_card/1, Map.put_new(assigns, :name, "Marta Ribeiro"))
  end

  describe "seller_card" do
    test "names the seller" do
      assert render_card(%{}) =~ "Marta Ribeiro"
    end

    test "renders an avatar for the seller" do
      html = render_card(%{})

      assert html =~ ~s(aria-label="Marta Ribeiro")
    end

    test "renders the seller's photo when there is one" do
      assert render_card(%{src: "/uploads/marta.png"}) =~ "/uploads/marta.png"
    end

    test "renders the meta line under the name when given one" do
      assert render_card(%{meta: "Selling on Mercato since 2023"}) =~
               "Selling on Mercato since 2023"
    end

    test "leaves the meta line out rather than rendering an empty one" do
      refute render_card(%{}) =~ ~s(data-role="seller-meta")
    end

    test "renders badges beside the name" do
      html =
        render_component(
          &SellerCard.seller_card/1,
          %{name: "Marta Ribeiro", badges: slot(:badges, "Verified")}
        )

      assert html =~ ~s(data-role="seller-badges")
      assert html =~ "Verified"
    end

    test "renders actions when given them" do
      html =
        render_component(
          &SellerCard.seller_card/1,
          %{name: "Marta Ribeiro", actions: slot(:actions, "Follow")}
        )

      assert html =~ ~s(data-role="seller-actions")
      assert html =~ "Follow"
    end

    test "leaves the action area out when there is nothing to do" do
      refute render_card(%{}) =~ ~s(data-role="seller-actions")
    end
  end
end
