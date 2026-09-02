defmodule MercatoWeb.UI.QuantityStepperTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.QuantityStepper

  defp stepper(assigns) do
    LazyHTML.from_fragment(
      render_component(
        &QuantityStepper.quantity_stepper/1,
        Keyword.merge(
          [id: "qty-1", value: 2, max: 5, label: "Chair"],
          assigns
        )
      )
    )
  end

  defp query(selector, assigns \\ []), do: assigns |> stepper() |> LazyHTML.query(selector)

  test "shows the quantity in force" do
    assert query("#qty-1-value") |> LazyHTML.text() =~ "2"
  end

  # The number changes without the row around it moving, so a screen reader is
  # told rather than left to notice.
  test "announces the quantity when it changes" do
    assert query("#qty-1-value") |> LazyHTML.attribute("aria-live") == ["polite"]
  end

  test "names each button by what it does and to what" do
    assert query("#qty-1-decrease") |> LazyHTML.attribute("aria-label") == [
             "Decrease the quantity of Chair"
           ]

    assert query("#qty-1-increase") |> LazyHTML.attribute("aria-label") == [
             "Increase the quantity of Chair"
           ]
  end

  test "carries the quantity each button would move to, so a caller need not compute it" do
    assert query("#qty-1-decrease") |> LazyHTML.attribute("phx-value-quantity") == ["1"]
    assert query("#qty-1-increase") |> LazyHTML.attribute("phx-value-quantity") == ["3"]
  end

  # A line of none is not an intention to buy, so the floor is one and removing
  # the line is how a buyer says otherwise.
  test "cannot go below one" do
    assert query("#qty-1-decrease", value: 1) |> LazyHTML.attribute("disabled") == [""]
  end

  test "cannot go past what the seller has" do
    assert query("#qty-1-increase", value: 5) |> LazyHTML.attribute("disabled") == [""]
  end

  test "passes a caller's events through to both buttons" do
    assert query("#qty-1-increase", "phx-click": "set_quantity")
           |> LazyHTML.attribute("phx-click") == ["set_quantity"]
  end

  test "hides its icons from a screen reader, which has the button names already" do
    assert query("button .hero-minus") |> LazyHTML.attribute("aria-hidden") == ["true"]
    assert query("button .hero-plus") |> LazyHTML.attribute("aria-hidden") == ["true"]
  end
end
