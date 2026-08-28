defmodule MercatoWeb.UI.AddToCartTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.AddToCart

  defp button(assigns \\ []) do
    LazyHTML.from_fragment(
      render_component(&AddToCart.add_to_cart/1, Keyword.merge([id: "add-to-cart-1"], assigns))
    )
  end

  defp query(selector, assigns \\ []), do: assigns |> button() |> LazyHTML.query(selector)

  # The label is dropped rather than absent: the control sits over the photo,
  # where a worded button would cover what is being sold.
  test "carries the name its icon does not show" do
    assert query("button") |> LazyHTML.attribute("aria-label") == ["Add to cart"]
  end

  test "hides its icon from a screen reader, which has the name already" do
    assert query("button .hero-plus") |> LazyHTML.attribute("aria-hidden") == ["true"]
  end

  test "answers to the id it was given, so a grid can address one card's button" do
    assert query("#add-to-cart-1") |> Enum.count() == 1
  end

  test "is a button rather than a link, since it acts instead of going somewhere" do
    assert query("button") |> LazyHTML.attribute("type") == ["button"]
  end

  # The cart it writes to is a separate concern, so the control is drawn live
  # rather than dimmed — it is not the buyer who is missing something.
  test "is available, whatever exists behind it" do
    assert query("button") |> LazyHTML.attribute("disabled") == []
  end
end
